import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';

/// Строка товара: миниатюра 58x58, название 13, описание 10.5, цена 800.
/// Справа круглая кнопка + 26x26 fox.
class ProductTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onOpen;
  const ProductTile({super.key, required this.item, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final price = s.fulfillment == Fulfillment.dineIn ? item.dineInPrice : item.takeawayPrice;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: SCColors.milk,
          borderRadius: BorderRadius.circular(SCRadii.productCard),
          border: Border.all(color: SCColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: SCColors.placeholder,
                borderRadius: BorderRadius.circular(SCRadii.thumb),
              ),
              child: Center(
                  child: Text(item.givesStamp ? '☕' : '🥐',
                      style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: sans(13, w: FontWeight.w700)),
                  if (item.description != null)
                    Text(item.description!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: sans(10.5, c: SCColors.muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rub(price), style: sans(13, w: FontWeight.w800)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.read<Session>().add(item.id),
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(color: SCColors.fox, shape: BoxShape.circle),
                    child: const Center(
                        child: Text('+',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Переключатель В кружке / С собой: выбранный сегмент espresso/cream.
class OrderTypeSwitch extends StatelessWidget {
  const OrderTypeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    Widget seg(Fulfillment f, String title, String sub) {
      final on = s.fulfillment == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => context.read<Session>().setFulfillment(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: on ? SCColors.espresso : Colors.transparent,
              borderRadius: BorderRadius.circular(SCRadii.segInner),
            ),
            child: Column(
              children: [
                Text(title,
                    style: sans(11, w: FontWeight.w700,
                        c: on ? SCColors.cream : SCColors.espresso)),
                Text(sub,
                    style: sans(9.5,
                        c: on ? SCColors.cream.withValues(alpha: 0.75) : SCColors.muted)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SCColors.milk,
        borderRadius: BorderRadius.circular(SCRadii.seg),
        border: Border.all(color: SCColors.line),
      ),
      child: Row(children: [
        seg(Fulfillment.dineIn, 'В кружке', '+1 печать'),
        seg(Fulfillment.takeaway, 'С собой', 'дешевле'),
      ]),
    );
  }
}


/// Выбор размера S/M/L: выбранный — граница fox 1.5, текст fox, фон foxTint.
class SizePicker extends StatelessWidget {
  final int index;
  final ValueChanged<int> onPick;
  const SizePicker({super.key, required this.index, required this.onPick});

  @override
  Widget build(BuildContext context) {
    const labels = ['S 250 мл', 'M 350 мл', 'L 450 мл'];
    return Row(
      children: List.generate(3, (i) {
        final on = i == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onPick(i),
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? SCColors.foxTint : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: on ? SCColors.fox : SCColors.line,
                    width: on ? 1.5 : 1),
              ),
              child: Text(labels[i],
                  style: sans(11, w: FontWeight.w700,
                      c: on ? SCColors.fox : SCColors.espresso)),
            ),
          ),
        );
      }),
    );
  }
}
