import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';
import 'checkout_screen.dart';

/// Корзина: список, OrderTypeSwitch, CTA «Заказать», результат/ошибка.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void goCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
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
            Row(
              children: [
                const ScBackButton(),
                const SizedBox(width: 10),
                Text('Корзина', style: serif(21)),
              ],
            ),
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
                left: 'Перейти к оплате',
                right: rub(s.cartTotal),
                onTap: goCheckout,
              ),
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
