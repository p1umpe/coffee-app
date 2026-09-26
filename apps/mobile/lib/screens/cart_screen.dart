import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';

/// Корзина: список, OrderTypeSwitch, CTA «Заказать», результат/ошибка.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool busy = false;
  String? result;
  String? error;

  Future<void> checkout() async {
    final s = context.read<Session>();
    if (s.shopId == null || s.userId == null || s.cart.isEmpty) return;
    setState(() { busy = true; error = null; result = null; });
    try {
      final r = await s.api.dio.post('/orders', data: {
        'shopId': s.shopId,
        'fulfillment': s.fulfillment.api,
        'userId': s.userId,
        'idempotencyKey': const Uuid().v4(),
        'items': s.cart.entries
            .map((e) => {'productId': e.key, 'qty': e.value})
            .toList(),
      });
      final d = r.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          result = 'Заказ ${d['number']} создан! ~${d['etaMin'] ?? 7} мин. '
              'Покажи QR из Профиля — получишь ${d['stampsEarned']} печати 🦊';
        });
      }
      s.clearCart();
      await s.refreshLoyalty();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (mounted) {
        setState(() => error = msg is String
            ? msg
            : 'Бэк недоступен — повтори, когда появится сеть 🦊');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final items = s.cart.entries.toList();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Text('Корзина', style: serif(21)),
            Text('Кофейня на ${s.shopName}',
                style: sans(11, c: SCColors.muted)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SCColors.milk,
                  borderRadius:
                      BorderRadius.circular(SCRadii.productCard),
                  border: Border.all(color: SCColors.line),
                ),
                child: Text(
                    'Пока тут пусто, но капучино уже скучает 🦊\nДобавь что-нибудь во вкладке «Меню».',
                    style: sans(13)),
              ),
            for (final e in items) ...[
              _row(s, e.key, e.value),
              const SizedBox(height: 8),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 4),
              const OrderTypeSwitch(),
              const SizedBox(height: 6),
              Text(
                s.fulfillment == Fulfillment.dineIn
                    ? 'Подадим в зале · +${s.cartStampsDue} печати'
                    : 'С собой · дешевле · без печатей',
                style: sans(11, c: SCColors.muted),
              ),
              const SizedBox(height: 12),
              CtaButton(
                left: busy ? 'Создаём заказ…' : 'Заказать · ~7 мин',
                right: rub(s.cartTotal),
                onTap: busy ? null : checkout,
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: SCColors.okBg,
                    borderRadius: BorderRadius.circular(14)),
                child: Text(result!,
                    style: sans(12.5, c: SCColors.okText)),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              NetErrorBanner(onRetry: checkout),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(Session s, String id, int qty) {
    final found = s.menuCache.where((x) => x.id == id);
    final title = found.isEmpty ? id : found.first.title;
    final price = found.isEmpty ? 0 : s.priceOf(found.first);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SCColors.milk,
        borderRadius: BorderRadius.circular(SCRadii.productCard),
        border: Border.all(color: SCColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: sans(13, w: FontWeight.w700)),
                Text('${rub(price)} × $qty',
                    style: sans(11, c: SCColors.muted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => s.remove(id),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.remove_circle_outline, size: 22),
            ),
          ),
          Text('$qty', style: sans(14, w: FontWeight.w800)),
          GestureDetector(
            onTap: () => s.add(id),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add_circle, size: 22, color: SCColors.fox),
            ),
          ),
        ],
      ),
    );
  }
}
