import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';

/// Настройки (task_0015): кофейня, локальные тумблеры пушей, о приложении, удаление аккаунта.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool orderStatus = true;
  bool promos = false;
  bool busy = false;

  void _goPickShop() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Выбери на табе Кофейни')),
    );
  }

  Future<bool> _ask(String title, String body, String ok, {bool danger = false}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(ok,
                style: danger ? const TextStyle(color: Colors.red) : null),
          ),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _confirmDelete(Session s) async {
    if (!await _ask('Удалить аккаунт?',
        'Печати, купоны и история будут потеряны.', 'Продолжить')) {
      return;
    }
    if (!mounted) return;
    if (!await _ask('Точно удалить?', 'Это действие необратимо.', 'Удалить',
        danger: true)) {
      return;
    }
    setState(() => busy = true);
    try {
      await s.api.dio.delete('/users/me');
      s.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg is String
                ? msg
                : 'Не удалось удалить аккаунт. Проверь связь с API.')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                const ScBackButton(),
                const SizedBox(width: 10),
                Text('Настройки', style: serif(21)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Любимая кофейня', style: serif(16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: SCColors.milk,
              borderRadius: BorderRadius.circular(SCRadii.shopCard),
              border: Border.all(color: SCColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(s.shopName,
                        style: sans(13, w: FontWeight.w700))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _goPickShop,
                  child: Text('Сменить',
                      style: sans(12, w: FontWeight.w800, c: SCColors.fox)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Push-уведомления', style: serif(16)),
          const SizedBox(height: 4),
          Text('Включатся с боевым push',
              style: sans(11, c: SCColors.muted)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: SCColors.milk,
              borderRadius: BorderRadius.circular(SCRadii.shopCard),
              border: Border.all(color: SCColors.line),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Статус заказа',
                      style: sans(13, w: FontWeight.w700)),
                  value: orderStatus,
                  activeThumbColor: SCColors.fox,
                  onChanged: (v) => setState(() => orderStatus = v),
                ),
                const Divider(height: 1, color: SCColors.line),
                SwitchListTile(
                  title: Text('Акции', style: sans(13, w: FontWeight.w700)),
                  value: promos,
                  activeThumbColor: SCColors.fox,
                  onChanged: (v) => setState(() => promos = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('О приложении', style: serif(16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: SCColors.milk,
              borderRadius: BorderRadius.circular(SCRadii.shopCard),
              border: Border.all(color: SCColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Версия 0.3.0', style: sans(13, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Сделано с 🦊', style: sans(11, c: SCColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: busy ? null : () => _confirmDelete(context.read<Session>()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(SCRadii.cta),
              ),
              child: Text(busy ? 'Удаляем…' : 'Удалить аккаунт',
                  style: sans(14, w: FontWeight.w800, c: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
