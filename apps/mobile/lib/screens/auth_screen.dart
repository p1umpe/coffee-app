import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';

/// Вход по телефону: запросить OTP -> ввести код (в dev код виден в API) -> JWT.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final phoneCtl = TextEditingController(text: '+79000000000');
  final codeCtl = TextEditingController();
  bool codeSent = false;
  String? devCode;
  String? error;
  bool busy = false;

  Future<void> request() async {
    final s = context.read<Session>();
    setState(() { busy = true; error = null; });
    try {
      final r = await s.api.dio.post('/auth/otp/request', data: {'phone': phoneCtl.text});
      setState(() {
        codeSent = true;
        devCode = r.data['devCode']?.toString();
        if (devCode != null) codeCtl.text = devCode!;
      });
    } on DioException catch (e) {
      setState(() => error = e.response?.data?['message']?.toString() ?? 'Нет связи с API :3000. Проверь, что бэк запущен.');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    final s = context.read<Session>();
    setState(() { busy = true; error = null; });
    try {
      final r = await s.api.dio.post('/auth/otp/verify',
          data: {'phone': phoneCtl.text, 'code': codeCtl.text.trim()});
      s.phone = phoneCtl.text;
      s.applyUser(Map<String, dynamic>.from(r.data['user'] as Map), r.data['accessToken'] as String);
    } on DioException catch (e) {
      setState(() => error = e.response?.data?['message']?.toString() ?? 'Неверный код');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            const Text('🦊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            const Text('Simple Coffee', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: SCColors.espresso)),
            const Text('Заказ без очереди. В кружке — печати, с собой — дешевле.',
                style: TextStyle(color: SCColors.secondary, fontSize: 15)),
            const SizedBox(height: 28),
            TextField(
              controller: phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder(), prefixText: ''),
            ),
            const SizedBox(height: 12),
            if (!codeSent)
              FilledButton(onPressed: busy ? null : request, child: Text(busy ? 'Отправляю…' : 'Получить код')),
            if (codeSent) ...[
              TextField(
                controller: codeCtl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Код из SMS',
                  border: const OutlineInputBorder(),
                  helperText: devCode != null ? 'dev-режим: код $devCode (подставился сам)' : null,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: busy ? null : verify, child: Text(busy ? 'Проверяю…' : 'Войти')),
              TextButton(onPressed: busy ? null : request, child: const Text('Запросить код ещё раз')),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
                child: Text(error!, style: const TextStyle(color: Color(0xFF9A3412))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
