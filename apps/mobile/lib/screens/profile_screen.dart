import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/stamp_shop.dart';

/// Профиль: приветствие + StampCard + QR гостя + выход.
/// (Полноценная история заказов и детали печатей — по разделу 5 спеки, позже.)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                    Text('Привет, ${s.userName}!', style: serif(21)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SCColors.milk,
                borderRadius: BorderRadius.circular(SCRadii.shopCard),
                border: Border.all(color: SCColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QR гостя — покажи бариста при выдаче в кружке',
                      style: sans(13, w: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 150, height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SCColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SCColors.line),
                      ),
                      // Без новой зависимости: код текстом + иконка.
                      // Сканер бариста читает SelectableText ниже.
                      child: const Text('🦊', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SelectableText(s.guestQr ?? '—',
                        style: sans(11, c: SCColors.muted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SCColors.milk,
                borderRadius: BorderRadius.circular(SCRadii.shopCard),
                border: Border.all(color: SCColors.line),
              ),
              child: Row(
                children: [
                  const Text('🦊', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Скоро: игра «Лис бежит за зёрнами»',
                            style: sans(13, w: FontWeight.w700)),
                        Text(
                            'Скоратишь ожидание, пока готовится кофе. Движок Flame уже заложен — выйдет в v2.0.',
                            style: sans(11, c: SCColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
