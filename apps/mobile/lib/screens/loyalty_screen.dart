import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';

/// Карточка лояльности: 6 кружек, QR гостя для скана бариста, задел под игру.
class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});
  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
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
    const need = 6;
    final have = s.stamps % need == 0 && s.stamps > 0 ? need : s.stamps % need;
    final shown = s.stamps == 0 ? 0 : (s.stamps % need == 0 ? need : s.stamps % need);
    return Scaffold(
      appBar: AppBar(title: const Text('Мои печати')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('Карточка гостя 🦊', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('Пей в кружке — копи печати. $need печатей = 7-й кофе бесплатно.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: SCColors.secondary, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(need, (i) {
                      final filled = i < (s.stamps >= need && s.stamps % need == 0 ? need : s.stamps % need);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: filled ? SCColors.fox : SCColors.cream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: filled ? SCColors.fox : SCColors.line),
                          ),
                          child: Center(
                              child: Text('🍵',
                                  style: TextStyle(
                                      fontSize: 22,
                                      color: filled ? null : const Color(0xFFB9A99B)))),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.stamps == 0
                        ? 'Пока 0 — закажи «В кружке» и покажи QR бариста'
                        : 'Печатей: ${s.stamps} · до бесплатного осталось ${need - (s.stamps % need == 0 ? need : s.stamps % need)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('Покажи бариста при выдаче в кружке',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (s.guestQr != null)
                    QrImageView(data: s.guestQr!, version: QrVersions.auto, size: 190)
                  else
                    const Text('Войди, чтобы получить QR'),
                  const SizedBox(height: 8),
                  SelectableText(s.guestQr ?? '',
                      style: const TextStyle(fontSize: 11, color: SCColors.secondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Text('🦊', style: TextStyle(fontSize: 28)),
              title: const Text('Скоро: игра «Лис бежит за зёрнами»'),
              subtitle: const Text(
                  'Скоратишь ожидание, пока готовится кофе. Зёрна обменяешь на сироп. Уже заложили движок Flame — выйдет в v2.0.'),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
