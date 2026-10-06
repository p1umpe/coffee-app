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
                if (widget.item.kbju != null) ...[
                  const SizedBox(height: 10),
                  _KbjuCard(kbju: widget.item.kbju!),
                ],
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

/// Аккордеон КБЖУ (task_0014): скрыт, если kbju == null.
/// Формат API: {kcal, protein, fat, carbs} — числа.
class _KbjuCard extends StatefulWidget {
  final Map<String, dynamic> kbju;
  const _KbjuCard({required this.kbju});

  @override
  State<_KbjuCard> createState() => _KbjuCardState();
}

class _KbjuCardState extends State<_KbjuCard> {
  bool open = false;

  String fmt(String k) {
    final v = widget.kbju[k];
    if (v is int) return '$v';
    if (v is double) return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return v?.toString() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SCColors.milk,
        borderRadius: BorderRadius.circular(SCRadii.productCard),
        border: Border.all(color: SCColors.line),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => open = !open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Состав и КБЖУ',
                      style: sans(13, w: FontWeight.w700)),
                  Row(
                    children: [
                      Text('${fmt('kcal')} ккал',
                          style: sans(12, c: SCColors.muted)),
                      const SizedBox(width: 4),
                      Icon(
                          open
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: SCColors.muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _cell('Белки', fmt('protein')),
                  _cell('Жиры', fmt('fat')),
                  _cell('Углеводы', fmt('carbs')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(String l, String v) {
    return Column(
      children: [
        Text(v, style: sans(14, w: FontWeight.w800)),
        Text(l, style: sans(10.5, c: SCColors.muted)),
      ],
    );
  }
}
