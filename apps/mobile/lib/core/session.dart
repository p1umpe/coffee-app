import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'categories.dart';
import '../theme/app_tokens.dart';

/// Сессия: гость, кофейня, режим кружка/с собой, корзина, категории меню.
class Session extends ChangeNotifier {
  final ApiClient api = ApiClient();

  String? userId;
  String? guestQr;
  String userName = 'Гость';
  int stamps = 0;
  int stampsNeed = 6; // из бэка STAMPS_TO_FREE_CUP; в макете 8 — пример
  String? phone;

  String? shopId;
  String shopName = 'Выбери кофейню 🦊';

  Fulfillment fulfillment = Fulfillment.dineIn;

  // productId -> qty
  final Map<String, int> cart = {};
  List<MenuItem> menuCache = [];
  /// Слаги категорий в порядке появления в меню: coffee, bakery, dessert, ...
  /// Слаги стабильны, в отличие от заголовков («Кофе и напитки»).
  List<String> categories = [];
  /// slug -> человекочитаемое название категории («Кофе и напитки»).
  Map<String, String> categoryTitles = {};
  /// Активный slug категории ('' — показываем всё меню).
  String activeCategory = '';

  bool get loggedIn => userId != null;
  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  int priceOf(MenuItem m) =>
      fulfillment == Fulfillment.dineIn ? m.dineInPrice : m.takeawayPrice;

  int get cartTotal => cart.entries.fold(0, (sum, e) {
        final m = menuCache.where((x) => x.id == e.key);
        if (m.isEmpty) return sum;
        return sum + priceOf(m.first) * e.value;
      });

  int get cartStampsDue {
    if (fulfillment != Fulfillment.dineIn) return 0;
    var n = 0;
    for (final e in cart.entries) {
      final m = menuCache.where((x) => x.id == e.key);
      if (m.isEmpty) continue;
      if (m.first.givesStamp) n += e.value;
    }
    return n;
  }

  List<MenuItem> get filteredMenu {
    if (activeCategory.isEmpty) return menuCache;
    return menuCache.where((m) => m.categorySlug == activeCategory).toList();
  }

  /// Название активной категории для UI (пусто — показываем всё меню).
  String get activeCategoryTitle =>
      activeCategory.isEmpty ? '' : categoryTitles[activeCategory] ?? activeCategory;

  void setShop(String id, String name) {
    shopId = id;
    shopName = name;
    cart.clear();
    menuCache = [];
    categories = [];
    categoryTitles = {};
    activeCategory = '';
    notifyListeners();
  }

  void setFulfillment(Fulfillment f) {
    fulfillment = f;
    notifyListeners();
  }

  /// Выбрать категорию по slug (см. [categories]).
  void setCategory(String slug) {
    activeCategory = slug;
    notifyListeners();
  }

  void setMenu(List<MenuItem> items) {
    menuCache = items;
    final slugs = <String>[];
    final titles = <String, String>{};
    for (final m in items) {
      final slug = m.categorySlug;
      if (slug.isEmpty) continue;
      if (!slugs.contains(slug)) slugs.add(slug);
      titles.putIfAbsent(slug, () => m.categoryTitle.isNotEmpty ? m.categoryTitle : categoryTitleForSlug(slug));
    }
    categories = sortCategorySlugs(slugs);
    categoryTitles = titles;
    // Если выбранной категории больше нет в меню — показываем всё меню.
    if (!slugs.contains(activeCategory)) activeCategory = '';
    notifyListeners();
  }

  void add(String id) {
    cart[id] = (cart[id] ?? 0) + 1;
    notifyListeners();
  }

  void remove(String id) {
    final q = (cart[id] ?? 0) - 1;
    if (q <= 0) {
      cart.remove(id);
    } else {
      cart[id] = q;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  void applyUser(Map<String, dynamic> u, String token, {String? phone}) {
    api.token = token;
    userId = u['id'] as String;
    guestQr = u['guestQr'] as String;
    stamps = (u['stamps'] as num?)?.toInt() ?? 0;
    if (phone != null) this.phone = phone;
    final p = (this.phone ?? '').replaceAll(RegExp(r'\D'), '');
    userName = p.length >= 4 ? 'Гость ${p.substring(p.length - 4)}' : 'Гость';
    notifyListeners();
  }

  List<Coupon> coupons = [];
  String? appliedCouponCode; // купон, выбранный для текущей корзины

  void applyCoupon(String code) {
    appliedCouponCode = code;
    notifyListeners();
  }

  void clearCoupon() {
    appliedCouponCode = null;
    notifyListeners();
  }

  /// Полный сброс сессии (удаление аккаунта / выход).
  void logout() {
    userId = null;
    guestQr = null;
    stamps = 0;
    coupons = [];
    cart.clear();
    appliedCouponCode = null;
    notifyListeners();
  }

  Future<void> refreshLoyalty() async {
    if (userId == null) return;
    try {
      final r = await api.dio.get('/loyalty/me/$userId');
      stamps = (r.data['stamps'] as num).toInt();
      final list = (r.data['coupons'] as List?) ?? [];
      coupons = list
          .map((e) => Coupon.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Сбросим применённый купон, если его больше нет / использован
      if (appliedCouponCode != null &&
          !coupons.any((c) => c.code == appliedCouponCode)) {
        appliedCouponCode = null;
      }
      notifyListeners();
    } on DioException {
      // офлайн — оставляем кэш
    }
  }
}

class Coupon {
  final String code;
  final DateTime expiresAt;
  const Coupon({required this.code, required this.expiresAt});

  Coupon.fromJson(Map<String, dynamic> j)
      : code = j['code'] as String,
        expiresAt = DateTime.parse(j['expiresAt'] as String);

  int daysLeft(DateTime now) => expiresAt.difference(now).inDays;
}

class MenuItem {
  final String id;
  final String title;
  final String? description;
  /// slug категории из API (`coffee`). Пустая строка — категории нет.
  final String categorySlug;
  /// Заголовок категории из API («Кофе и напитки») — только для показа.
  final String categoryTitle;
  final int dineInPrice;
  final int takeawayPrice;
  final bool givesStamp;
  final List<String> tags;
  final Map<String, dynamic>? kbju; // {kcal, protein, fat, carbs} — из API, может быть null

  MenuItem.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        description = j['description'] as String?,
        categorySlug = _parseCategorySlug(j['category']),
        categoryTitle = _parseCategoryTitle(j['category']),
        dineInPrice = (j['dineInPrice'] as num).toInt(),
        takeawayPrice = (j['takeawayPrice'] as num).toInt(),
        givesStamp = (j['givesStamp'] as bool?) ?? false,
        tags = ((j['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
        kbju = (j['kbju'] is Map)
            ? Map<String, dynamic>.from(j['kbju'] as Map)
            : null;

  /// slug категории: из объекта {slug,title}, из строки-заголовка или из title.
  static String _parseCategorySlug(Object? raw) {
    if (raw is Map) {
      final slug = raw['slug']?.toString() ?? '';
      if (slug.isNotEmpty) return slug;
      final title = raw['title']?.toString() ?? '';
      return categorySlugFromTitle(title);
    }
    final s = raw?.toString() ?? '';
    if (s.isEmpty) return '';
    return categorySlugFromTitle(s);
  }

  /// Заголовок категории: из объекта {slug,title} или из строки.
  static String _parseCategoryTitle(Object? raw) {
    if (raw is Map) return raw['title']?.toString() ?? '';
    return raw?.toString() ?? '';
  }

  /// Мок для витрины, пока API пустое: цены как в макете.
  static List<MenuItem> mock() => [
        _m('Латте', 'Эспрессо, молоко', 'coffee', 'Кофе и напитки', 26000, true),
        _m('Флэт уайт', 'Двойной эспрессо', 'coffee', 'Кофе и напитки', 24000, true),
        _m('Мокка', 'Шоколад, эспрессо', 'coffee', 'Кофе и напитки', 29000, true),
        _m('Круассан', 'Сливочное масло', 'bakery', 'Выпечка', 19000, false),
      ];

  static MenuItem _m(String t, String d, String cSlug, String cTitle, int p, bool s) =>
      MenuItem.fromJson({
        'id': 'mock-$t', 'title': t, 'description': d,
        'category': {'slug': cSlug, 'title': cTitle}, 'dineInPrice': p,
        // Скидка −30 ₽ только на напитки (givesStamp). Еда — та же цена.
        'takeawayPrice': s ? p - 3000 : p, 'givesStamp': s, 'tags': [],
      });
}

