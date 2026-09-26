import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/product_widgets.dart';
import '../widgets/common.dart';

/// Экран заказа напитка по спеке 3.3: hero 150/r26, serif 21,
/// SizePicker, OrderTypeSwitch (выбранный espresso/cream), CTA с ценой.
class ProductScreen extends StatefulWidget {
  final MenuItem item;
  const ProductScreen({super.key, required this.item});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int sizeIndex = 1; // M по умолчанию, как в макете

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final price = s.priceOf(widget.item);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: SCColors.milk,
                          shape: BoxShape.circle,
                          border: Border.all(color: SCColors.line),
                        ),
                        child: const Icon(Icons.arrow_back, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: SCColors.placeholder,
                    borderRadius: BorderRadius.circular(SCRadii.hero),
                  ),
                  child: Center(
                      child: Text(widget.item.givesStamp ? '☕' : '🥐',
                          style: const TextStyle(fontSize: 84))),
                ),
                const SizedBox(height: 12),
                Text(widget.item.title, style: serif(21)),
                Text(widget.item.description ?? '',
                    style: sans(11.5, c: SCColors.muted)),
                const SizedBox(height: 12),
                SizePicker(
                    index: sizeIndex, onPick: (i) => setState(() => sizeIndex = i)),
                const SizedBox(height: 8),
                const OrderTypeSwitch(),
                const SizedBox(height: 10),
                Text('Молоко: обычное · Сироп: без',
                    style: sans(11, c: SCColors.muted)),
              ],
            ),
            Positioned(
              left: 16, right: 16, bottom: 12,
              child: CtaButton(
                left: 'Добавить',
                right: rub(price),
                onTap: () {
                  context.read<Session>().add(widget.item.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${widget.item.title} добавлен 🦊 (+${s.fulfillment == Fulfillment.dineIn && widget.item.givesStamp ? 1 : 0} печати)')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
