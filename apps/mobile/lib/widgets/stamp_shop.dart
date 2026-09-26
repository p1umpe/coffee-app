import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Тёмная карта лояльности: espresso, r22. Сетка печатей 4x2, последняя — подарок.
class StampCard extends StatelessWidget {
  final int have; // уже собрано (без учёта подарочной ячейки)
  final int need; // печатей до бесплатного (по бэку 6; в макете 8 — пример)
  const StampCard({super.key, required this.have, required this.need});

  @override
  Widget build(BuildContext context) {
    final total = need + 1; // +1 ячейка-подарок
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SCColors.espresso,
        borderRadius: BorderRadius.circular(SCRadii.loyaltyCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Твоя карта',
              style: sans(11, c: SCColors.cream.withValues(alpha: 0.7))),
          const SizedBox(height: 2),
          Text('$have из $need печатей',
              style: serif(15, w: FontWeight.w800, c: SCColors.cream)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: total,
            itemBuilder: (_, i) {
              if (i == total - 1) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: SCColors.cream.withValues(alpha: 0.35),
                        style: BorderStyle.solid),
                  ),
                  child: const Center(child: Text('🎁', style: TextStyle(fontSize: 16))),
                );
              }
              final filled = i < have;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? SCColors.fox : Colors.transparent,
                  border: filled
                      ? null
                      : Border.all(
                          color: SCColors.cream.withValues(alpha: 0.35),
                          style: BorderStyle.solid),
                ),
                child: Center(
                    child: Text('☕',
                        style: TextStyle(
                            fontSize: 16,
                            color: filled
                                ? Colors.white
                                : SCColors.cream.withValues(alpha: 0.4)))),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _hint('☕ В кружке — печать'),
              const SizedBox(width: 6),
              _hint('🥡 С собой — дешевле'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hint(String t) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(t, style: sans(10.5, c: SCColors.cream)),
        ),
      );
}

/// Карточка кофейни: milk, r18, плашка Открыто/Закрыто.
class ShopTile extends StatelessWidget {
  final String name;
  final String address;
  final String meta; // "300 м · до 22:00"
  final bool open;
  final bool selected;
  final VoidCallback onTap;
  const ShopTile({super.key, required this.name, required this.address,
    required this.meta, required this.open, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: SCColors.milk,
          borderRadius: BorderRadius.circular(SCRadii.shopCard),
          border: Border.all(
              color: selected ? SCColors.fox : SCColors.line,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: sans(13, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$address · $meta', style: sans(10.5, c: SCColors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: open ? SCColors.okBg : SCColors.line.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(open ? 'Открыто' : 'Закрыто',
                  style: sans(10,
                      w: FontWeight.w700,
                      c: open ? SCColors.okText : SCColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
