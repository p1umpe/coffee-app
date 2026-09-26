import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/stamp_shop.dart';

/// Главная по спеке 3.1: приветствие, StampCard, промо-баннер, категории.
class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenMenu;
  final ValueChanged<MenuItem> onOpenProduct;
  const HomeScreen({super.key, required this.onOpenMenu, required this.onOpenProduct});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greetingByHour(DateTime.now()),
                        style: sans(11, c: SCColors.muted)),
                    Text('Привет, ${s.userName}!',
                        style: serif(21)),
                  ],
                ),
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(
                      color: SCColors.caramel, shape: BoxShape.circle),
                  child: const Center(
                      child: Text('🦊', style: TextStyle(fontSize: 17))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StampCard(have: s.stamps, need: s.stampsNeed),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onOpenMenu,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SCRadii.banner),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [SCColors.caramel, SCColors.fox],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Осень уютнее\nс сезонными чаями',
                            style: serif(16, c: Colors.white)),
                        const SizedBox(height: 3),
                        Text('Новинки меню',
                            style: sans(12, c: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                    const Text('🍵', style: TextStyle(fontSize: 34)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Категории', style: sans(14, w: FontWeight.w700)),
                GestureDetector(
                  onTap: onOpenMenu,
                  child: Text('Всё меню',
                      style: sans(12, w: FontWeight.w600, c: SCColors.fox)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                _CatTile(emoji: '☕', label: 'Кофе'),
                SizedBox(width: 8),
                _CatTile(emoji: '🥐', label: 'Выпечка'),
                SizedBox(width: 8),
                _CatTile(emoji: '🍰', label: 'Десерты'),
                SizedBox(width: 8),
                _CatTile(emoji: '🍳', label: 'Завтраки'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  final String emoji;
  final String label;
  const _CatTile({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: SCColors.milk,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SCColors.line),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: sans(10, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
