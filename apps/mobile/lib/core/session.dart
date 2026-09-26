import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
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
  List<String> categories = [];
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
    return menuCache.where((m) => m.category == activeCategory).toList();
  }

  void setShop(String id, String name) {
    shopId = id;
    shopName = name;
    cart.clear();
    menuCache = [];
    categories = [];
    activeCategory = '';
    notifyListeners();
  }

  void setFulfillment(Fulfillment f) {
    fulfillment = f;
    notifyListeners();
  }

  void setCategory(String c) {
    activeCategory = c;
    notifyListeners();
  }

  void setMenu(List<MenuItem> items) {
    menuCache = items;
    final cats = <String>[];
    for (final m in items) {
      if (m.category.isNotEmpty && !cats.contains(m.category)) cats.add(m.category);
    }
    categories = cats;
    if (!cats.contains(activeCategory)) activeCategory = cats.isEmpty ? '' : cats.first;
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

  Future<void> refreshLoyalty() async {
    if (userId == null) return;
    try {
      final r = await api.dio.get('/loyalty/me/$userId');
      stamps = (r.data['stamps'] as num).toInt();
      notifyListeners();
    } on DioException {
      // офлайн — оставляем кэш
    }
  }
}

class MenuItem {
  final String id;
  final String title;
  final String? description;
  final String category;
  final int dineInPrice;
  final int takeawayPrice;
  final bool givesStamp;
  final List<String> tags;

  MenuItem.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        description = j['description'] as String?,
        category = (j['category'] is Map)
            ? ((j['category'] as Map)['title']?.toString() ?? '')
            : (j['category']?.toString() ?? ''),
        dineInPrice = (j['dineInPrice'] as num).toInt(),
        takeawayPrice = (j['takeawayPrice'] as num).toInt(),
        givesStamp = (j['givesStamp'] as bool?) ?? false,
        tags = ((j['tags'] as List?) ?? []).map((e) => e.toString()).toList();

  /// Мок для витрины, пока API пустое: цены как в макете.
  static List<MenuItem> mock() => [
        _m('Латте', 'Эспрессо, молоко', 'Кофе', 26000, true),
        _m('Флэт уайт', 'Двойной эспрессо', 'Кофе', 24000, true),
        _m('Мокка', 'Шоколад, эспрессо', 'Кофе', 29000, true),
        _m('Круассан', 'Сливочное масло', 'Выпечка', 19000, false),
      ];

  static MenuItem _m(String t, String d, String c, int p, bool s) =>
      MenuItem.fromJson({
        'id': 'mock-$t', 'title': t, 'description': d,
        'category': {'title': c}, 'dineInPrice': p,
        'takeawayPrice': p - 1000, 'givesStamp': s, 'tags': [],
      });
}

