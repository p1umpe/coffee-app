import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Вход по телефону в токенах спеки: serif-заголовок, milk-поля, fox-CTA.
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
      final r = await s.api.dio
          .post('/auth/otp/request', data: {'phone': phoneCtl.text});
      setState(() {
        codeSent = true;
        devCode = r.data['devCode']?.toString();
        if (devCode != null) codeCtl.text = devCode!;
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => error = msg is String
          ? msg
          : 'Нет связи с API :3000. Проверь, что бэк запущен.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    final s = context.read<Session>();
    setState(() { busy = true; error = null; });
    try {
      final r = await s.api.dio.post('/auth/otp/verify',
          data: {'phone': phoneCtl.text, 'code': codeCtl.text.trim()});
      s.applyUser(Map<String, dynamic>.from(r.data['user'] as Map),
          r.data['accessToken'] as String,
          phone: phoneCtl.text);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(
          () => error = msg is String ? msg : 'Неверный код');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          children: [
            const Text('🦊', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text('Simple Coffee', style: serif(28)),
            Text('Заказ без очереди. В кружке — печати, с собой — дешевле.',
                style: sans(15, c: SCColors.muted)),
            const SizedBox(height: 28),
            _field(phoneCtl, 'Телефон', TextInputType.phone),
            const SizedBox(height: 12),
            if (!codeSent)
              CtaButton(
                  left: busy ? 'Отправляю…' : 'Получить код',
                  right: '→',
                  onTap: busy ? null : request),
            if (codeSent) ...[
              _field(codeCtl, 'Код из SMS', TextInputType.number,
                  helper: devCode != null
                      ? 'dev-режим: код $devCode (подставился сам)'
                      : null),
              const SizedBox(height: 12),
              CtaButton(
                  left: busy ? 'Проверяю…' : 'Войти',
                  right: '→',
                  onTap: busy ? null : verify),
              const SizedBox(height: 4),
              Center(
                child: GestureDetector(
                  onTap: busy ? null : request,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Запросить код ещё раз',
                        style: sans(12,
                            w: FontWeight.w600, c: SCColors.fox)),
                  ),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              NetErrorBanner(onRetry: codeSent ? verify : request),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      TextInputType type, {String? helper}) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: sans(14),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: SCColors.milk,
        labelStyle: sans(12, c: SCColors.muted),
        helperStyle: sans(11, c: SCColors.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SCColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SCColors.fox, width: 1.5),
        ),
      ),
    );
  }
}
