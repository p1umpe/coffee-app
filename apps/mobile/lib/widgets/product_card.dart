import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final MenuItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final price = s.fulfillment == Fulfillment.dineIn ? item.dineInPrice : item.takeawayPrice;
    final qty = s.cart[item.id] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: SCColors.cream, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(item.givesStamp ? '☕' : '🥐', style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (item.tags.contains('new'))
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: SCColors.fox, borderRadius: BorderRadius.circular(20)),
                        child: const Text('new', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                  ]),
                  if (item.description != null)
                    Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: SCColors.secondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(rub(price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 8),
                    if (item.givesStamp && s.fulfillment == Fulfillment.dineIn)
                      const Text('+ печать 🦊', style: TextStyle(color: SCColors.fox, fontSize: 12, fontWeight: FontWeight.w600)),
                    if (!item.givesStamp)
                      const Text('без печати', style: TextStyle(color: SCColors.secondary, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            qty == 0
                ? IconButton.filled(onPressed: () => s.add(item.id), icon: const Icon(Icons.add))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => s.remove(item.id), icon: const Icon(Icons.remove_circle_outline)),
                    Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800)),
                    IconButton(onPressed: () => s.add(item.id), icon: const Icon(Icons.add_circle)),
                  ]),
          ],
        ),
      ),
    );
  }
}
