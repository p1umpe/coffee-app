import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Мои купоны: 7-й кофе бесплатно (6 печатей). QR текстом (qr-пакета нет),
/// кнопка «Применить» кладёт код в корзину (Session.appliedCouponCode).
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Session>().refreshLoyalty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final left = s.stampsNeed - (s.stamps % s.stampsNeed == 0 && s.stamps > 0
        ? s.stampsNeed
        : s.stamps % s.stampsNeed);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Text('Мои купоны', style: serif(21)),
            Text('6 печатей = 7-й кофе бесплатно',
                style: sans(11, c: SCColors.muted)),
            const SizedBox(height: 10),
            if (s.coupons.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SCColors.milk,
                  borderRadius:
                      BorderRadius.circular(SCRadii.productCard),
                  border: Border.all(color: SCColors.line),
                ),
                child: Text(
                    s.stamps == 0
                        ? 'Пока купонов нет 🦊\nПей в кружке — печати копятся сами.'
                        : 'До бесплатного кофе осталось $left ${left == 1 ? 'печать' : 'печати'} 🦊\nПей в кружке — купон появится здесь.',
                    style: sans(13)),
              ),
            ],
            for (final c in s.coupons) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SCColors.espresso,
                  borderRadius:
                      BorderRadius.circular(SCRadii.loyaltyCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Бесплатный кофе 🎁',
                        style: serif(16, c: SCColors.cream)),
                    Text(
                        'Покажи бариста · живёт ещё ~${c.daysLeft(DateTime.now())} дн.',
                        style: sans(11,
                            c: SCColors.cream
                                .withValues(alpha: 0.75))),
                    const SizedBox(height: 8),
                    Center(
                      child: SelectableText(c.code,
                          style: sans(15,
                              w: FontWeight.w800,
                              c: SCColors.cream)),
                    ),
                    const SizedBox(height: 10),
                    CtaButton(
                      left: s.appliedCouponCode == c.code
                          ? 'Применён ✓'
                          : 'Применить в корзине',
                      right: '0 ₽',
                      onTap: () {
                        context
                            .read<Session>()
                            .applyCoupon(c.code);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Купон применён — оформи 1 напиток в корзине 🦊')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
