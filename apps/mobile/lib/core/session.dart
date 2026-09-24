import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../theme/app_theme.dart';

/// Простая сессия без Riverpod — ChangeNotifier, новичку проще.
/// Хранит: гостя (userId, guestQr, stamps), выбранную кофейню, режим кружка/с собой, корзину.
class Session extends ChangeNotifier {
  final ApiClient api = ApiClient();

  String? userId;
  String? guestQr;
  int stamps = 0;
  String? phone;

  String? shopId;
  String shopName = 'Выбери кофейню 🦊';
  Fulfillment fulfillment = Fulfillment.dineIn;

  // productId -> qty
  final Map<String, int> cart = {};
  // кэш меню для подсчёта итога
  List<MenuItem> menuCache = [];

  bool get loggedIn => userId != null;
  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  int get cartTotal {
    var sum = 0;
    for (final e in cart.entries) {
      final m = menuCache.where((x) => x.id == e.key);
      if (m.isEmpty) continue;
      final item = m.first;
      sum += (fulfillment == Fulfillment.dineIn ? item.dineInPrice : item.takeawayPrice) * e.value;
    }
    return sum;
  }

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

  void setShop(String id, String name) {
    shopId = id;
    shopName = name;
    cart.clear();
    notifyListeners();
  }

  void setFulfillment(Fulfillment f) {
    fulfillment = f;
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

  void applyUser(Map<String, dynamic> u, String token) {
    api.token = token;
    userId = u['id'] as String;
    guestQr = u['guestQr'] as String;
    stamps = (u['stamps'] as num?)?.toInt() ?? 0;
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
  final int dineInPrice;
  final int takeawayPrice;
  final bool givesStamp;
  final List<String> tags;

  MenuItem.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        description = j['description'] as String?,
        dineInPrice = (j['dineInPrice'] as num).toInt(),
        takeawayPrice = (j['takeawayPrice'] as num).toInt(),
        givesStamp = (j['givesStamp'] as bool?) ?? false,
        tags = ((j['tags'] as List?) ?? []).map((e) => e.toString()).toList();
}
