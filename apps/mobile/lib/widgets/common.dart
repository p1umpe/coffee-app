import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Нижний таб-бар по спеке: milk + линия line, активный fox.
class AppTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final int cartCount;
  const AppTabBar({super.key, required this.index, required this.onTap, this.cartCount = 0});

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icon, String label) {
      final on = index == i;
      return Expanded(
        child: InkWell(
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: on ? SCColors.fox : SCColors.muted),
                    if (i == 1 && cartCount > 0)
                      Positioned(
                        right: -8, top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: SCColors.fox, shape: BoxShape.circle),
                          child: Text('$cartCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: on ? SCColors.fox : SCColors.muted)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: SCColors.milk,
        border: Border(top: BorderSide(color: SCColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          item(0, Icons.home_outlined, 'Главная'),
          item(1, Icons.coffee_outlined, 'Меню'),
          item(2, Icons.location_on_outlined, 'Кофейни'),
          item(3, Icons.person_outline, 'Профиль'),
        ]),
      ),
    );
  }
}

/// Чип категории: h~30, r14, активный espresso/cream.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const CategoryChip({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? SCColors.espresso : SCColors.milk,
          borderRadius: BorderRadius.circular(SCRadii.chip),
          border: Border.all(color: active ? SCColors.espresso : SCColors.line),
        ),
        child: Text(label,
            style: sans(11, w: FontWeight.w600,
                c: active ? SCColors.cream : SCColors.espresso)),
      ),
    );
  }
}

/// CTA: fox, r20, тень 0 8 18. Слева текст, справа цена.
class CtaButton extends StatelessWidget {

  final String left;
  final String right;
  final VoidCallback? onTap;
  const CtaButton({super.key, required this.left, required this.right, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: SCColors.fox,
          borderRadius: BorderRadius.circular(SCRadii.cta),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(226, 98, 43, 0.4), offset: Offset(0, 8), blurRadius: 18),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left, style: sans(14, w: FontWeight.w800, c: Colors.white)),
            Text(right, style: sans(14, w: FontWeight.w800, c: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Мягкий баннер ошибки сети (caramel).
class NetErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const NetErrorBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SCColors.caramel.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SCColors.caramel.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text('Нет связи с сервером. Показываем сохранённое 🦊',
                  style: sans(11.5, c: SCColors.espresso))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Text('Повторить',
                style: sans(12, w: FontWeight.w800, c: SCColors.fox)),
          ),
        ],
      ),
    );
  }
}

/// Скелетоны загрузки (серо-бежевые), без спиннера.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Container(
          height: 78,
          margin: const EdgeInsets.only(bottom: 9),
          decoration: BoxDecoration(
            color: SCColors.placeholder.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(SCRadii.productCard),
          ),
        ),
      ),
    );
  }
}
