import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Онбординг (task_0011): 3 слайда + CTA. Показывается 1 раз до входа.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ctrl = PageController();
  int page = 0;

  static const slides = [
    ('☕', 'Закажи без очереди', 'Выбери напиток и забери через ~7 минут. Никаких касс и ожидания.'),
    ('🦊', 'Копи лисички', 'Пей в кружке — получай печати. 6 печатей = 7-й кофе бесплатно.'),
    ('📍', 'Найди свою кофейню', 'Ближайшая точка, часы и меню — всё в приложении.'),
  ];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: ctrl,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (_, i) {
                  final (emoji, title, sub) = slides[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Column(
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 84)),
                        const SizedBox(height: 24),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: serif(24)),
                        const SizedBox(height: 10),
                        Text(sub,
                            textAlign: TextAlign.center,
                            style: sans(14,
                                c: SCColors.muted)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => Container(
                  width: page == i ? 22 : 8,
                  height: 8,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: page == i
                        ? SCColors.fox
                        : SCColors.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CtaButton(
                left: page < slides.length - 1
                    ? 'Дальше'
                    : 'Начать',
                right: '→',
                onTap: () {
                  if (page < slides.length - 1) {
                    ctrl.nextPage(
                      duration:
                          const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  } else {
                    widget.onDone();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            if (page < slides.length - 1)
              GestureDetector(
                onTap: widget.onDone,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('Пропустить',
                      style: sans(12,
                          w: FontWeight.w600,
                          c: SCColors.muted)),
                ),
              )
            else
              const SizedBox(height: 38),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
