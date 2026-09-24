import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';

/// Корзина: итог зависит от режима, создание заказа с idempotencyKey.
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
      setState(() {
        result =
            'Заказ ${d['number']} создан! Готовность ~${d['etaMin'] ?? 7} мин. Покажи QR из вкладки «Печати» бариста, чтобы получить ${d['stampsEarned']} печати 🦊';
      });
      s.clearCart();
      await s.refreshLoyalty();
    } on DioException catch (e) {
      setState(() => error = e.response?.data?['message']?.toString() ?? 'Не получилось создать заказ');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final items = s.cart.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Твой заказ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.shopName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    s.fulfillment == Fulfillment.dineIn
                        ? 'В кружке 🍵 · подадим в зале · +${s.cartStampsDue} печати'
                        : 'С собой 🥤 · дешевле · без печатей',
                    style: const TextStyle(color: SCColors.secondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Пока тут пусто, но капучино уже скучает 🦊\nДобавь что-нибудь во вкладке «Меню».'),
              ),
            ),
          for (final e in items)
            Builder(builder: (_) {
              final found = s.menuCache.where((x) => x.id == e.key);
              final title = found.isEmpty ? e.key : found.first.title;
              final price = found.isEmpty
                  ? 0
                  : (s.fulfillment == Fulfillment.dineIn
                      ? found.first.dineInPrice
                      : found.first.takeawayPrice);
              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('${rub(price)} × ${e.value}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: () => s.remove(e.key), icon: const Icon(Icons.remove_circle_outline)),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      IconButton(onPressed: () => s.add(e.key), icon: const Icon(Icons.add_circle)),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          if (items.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Итого', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(rub(s.cartTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ]),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy ? null : checkout,
                      child: Text(busy ? 'Создаём заказ…' : 'Заказать · забрать через ~7 мин'),
                    ),
                  ],
                ),
              ),
            ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEAF5EA), borderRadius: BorderRadius.circular(14)),
              child: Text(result!, style: const TextStyle(color: Color(0xFF2F6B2F))),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(14)),
              child: Text(error!),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
