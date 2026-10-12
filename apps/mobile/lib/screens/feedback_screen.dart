import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Напишите нам (task_0013, FLOW H): тема + текст, POST /feedback.
/// Фото чека — позже (нужен S3).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String topic = 'PRAISE';
  final textCtrl = TextEditingController();
  bool busy = false;
  bool done = false;
  String? error;

  static const topics = [
    ('PRAISE', 'Похвалить 💌'),
    ('COMPLAINT', 'Пожаловаться 🙏'),
    ('RENT', 'Аренда 🏠'),
    ('PARTNERSHIP', 'Сотрудничество 🤝'),
  ];

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final s = context.read<Session>();
    if (textCtrl.text.trim().length < 3 || busy) return;
    setState(() { busy = true; error = null; });
    try {
      await s.api.dio.post('/feedback', data: {
        'topic': topic,
        'text': textCtrl.text.trim(),
        if (s.userId != null) 'userId': s.userId,
        if (s.phone != null) 'contact': s.phone,
      });
      if (mounted) setState(() => done = true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (mounted) {
        setState(() => error =
            msg is String ? msg : 'Не отправилось — попробуй позже');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SCColors.milk,
                      shape: BoxShape.circle,
                      border: Border.all(color: SCColors.line),
                    ),
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Напишите нам', style: serif(21)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Мы любим получать письма! Ответим за день 💌',
                style: sans(11, c: SCColors.muted)),
            const SizedBox(height: 12),
            if (done)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: SCColors.okBg,
                    borderRadius: BorderRadius.circular(14)),
                child: Text(
                    'Спасибо! Письмо улетело — ответим за день 💌',
                    style: sans(13,
                        c: SCColors.okText, w: FontWeight.w700)),
              )
            else ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (v, label) in topics)
                    CategoryChip(
                      label: label,
                      active: topic == v,
                      onTap: () => setState(() => topic = v),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textCtrl,
                maxLines: 5,
                maxLength: 2000,
                style: sans(13),
                decoration: InputDecoration(
                  hintText: 'Расскажи, что случилось…',
                  hintStyle: sans(12, c: SCColors.muted),
                  filled: true,
                  fillColor: SCColors.milk,
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: SCColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: SCColors.fox, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CtaButton(
                left: busy ? 'Отправляем…' : 'Отправить',
                right: '💌',
                onTap: busy ? null : send,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                NetErrorBanner(onRetry: send),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
