import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_tokens.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';

/// Модель заказа из GET /v1/orders/my (include shop).
class HistoryOrderItem {
  final String productId;
  final int qty;
  HistoryOrderItem({required this.productId, required this.qty});
  factory HistoryOrderItem.fromJson(Map<String, dynamic> j) =>
      HistoryOrderItem(
        productId: (j['productId'] ?? '').toString(),
        qty: (j['qty'] as num?)?.toInt() ?? 1,
      );
}

class HistoryOrder {
  final String id;
  final String number;
  final String status;
  final int total;
  final String shopName;
  final List<HistoryOrderItem> items;
  HistoryOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.shopName,
    required this.items,
  });
  factory HistoryOrder.fromJson(Map<String, dynamic> j) {
    final shop = j['shop'];
    final raw = (j['items'] as List?) ?? [];
    return HistoryOrder(
      id: (j['id'] ?? '').toString(),
      number: (j['number'] ?? '—').toString(),
      status: (j['status'] ?? '').toString(),
      total: (j['total'] as num?)?.toInt() ?? 0,
      shopName: shop is Map ? (shop['name']?.toString() ?? '') : '',
      items: raw
          .whereType<Map>()
          .map((e) => HistoryOrderItem.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

String historyStatusLabel(String s) => switch (s) {
      'PENDING_PAYMENT' => 'Ожидает оплаты',
      'PAID' => 'Оплачен',
      'ACCEPTED' => 'Принят',
      'COOKING' => 'Готовится',
      'READY' => 'Готов',
      'SERVED' => 'Выдан',
      'CANCELLED' => 'Отменён',
      _ => s.isEmpty ? '—' : s,
    };

/// Статус-чип истории.
class HistoryStatusChip extends StatelessWidget {
  final String status;
  const HistoryStatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final ok = status == 'READY' || status == 'SERVED' || status == 'PAID';
    final bad = status == 'CANCELLED';
    final bg = bad ? SCColors.foxTint : (ok ? SCColors.okBg : SCColors.cream);
    final fg = bad ? SCColors.fox : (ok ? SCColors.okText : SCColors.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SCRadii.chip),
        border: Border.all(color: SCColors.line),
      ),
      child: Text(historyStatusLabel(status),
          style: sans(11, w: FontWeight.w700, c: fg)),
    );
  }
}

String historyTitleOf(Session s, String productId) {
  final f = s.menuCache.where((m) => m.id == productId);
  return f.isEmpty ? productId : f.first.title;
}

/// История заказов (task_0005): GET /orders/my?userId= + «Повторить».
class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});
  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryState();
}

class _OrdersHistoryState extends State<OrdersHistoryScreen> {
  bool loading = false;
  bool netError = false;
  List<HistoryOrder> orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final s = context.read<Session>();
    if (s.userId == null) return;
    if (mounted) setState(() { loading = true; netError = false; });
    try {
      final r = await s.api.dio.get('/orders/my',
          queryParameters: {'userId': s.userId, 'take': 20, 'skip': 0});
      final list = (r.data as List)
          .map((e) => HistoryOrder.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      if (mounted) setState(() => orders = list);
    } catch (_) {
      if (mounted) setState(() => netError = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void repeat(HistoryOrder o) {
    final s = context.read<Session>();
    s.clearCart();
    for (final it in o.items) {
      for (var i = 0; i < it.qty; i++) {
        s.add(it.productId);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Заказ ${o.number} повторён — проверь корзину 🦊')),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(title: Text('История заказов', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            if (netError)
              NetErrorBanner(onRetry: load),
            if (loading)
              const SkeletonList()
            else if (orders.isEmpty && !netError)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SCColors.milk,
                  borderRadius:
                      BorderRadius.circular(SCRadii.productCard),
                  border: Border.all(color: SCColors.line),
                ),
                child: Text(
                  'Пока заказов нет, но капучино уже скучает 🦊\nЗагляни в «Меню» — там вкусно.',
                  style: sans(13)),
              )
            else
              for (final o in orders) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SCColors.milk,
                    borderRadius:
                        BorderRadius.circular(SCRadii.productCard),
                    border: Border.all(color: SCColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Заказ ${o.number}', style: serif(17)),
                          HistoryStatusChip(o.status),
                        ],
                      ),
                      if (o.shopName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(o.shopName,
                            style: sans(11, c: SCColors.muted)),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        o.items
                            .map((e) =>
                                '${historyTitleOf(s, e.productId)} × ${e.qty}')
                            .join(', '),
                        style: sans(12)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rub(o.total),
                              style: sans(14, w: FontWeight.w800)),
                          GestureDetector(
                            onTap: () => repeat(o),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: SCColors.fox,
                                borderRadius: BorderRadius.circular(
                                    SCRadii.chip),
                              ),
                              child: Text('Повторить',
                                  style: sans(12,
                                      w: FontWeight.w800,
                                      c: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
              ],
          ],
        ),
      ),
    );
  }
}

