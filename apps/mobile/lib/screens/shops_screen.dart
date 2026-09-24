import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});
  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  List<Map<String, dynamic>> shops = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = context.read<Session>();
    setState(() { loading = true; error = null; });
    try {
      final r = await s.api.dio.get('/shops');
      shops = (r.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      error = e.message ?? 'Нет связи с API';
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(title: const Text('Кофейни рядом')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(error!), const SizedBox(height: 8),
                  FilledButton(onPressed: load, child: const Text('Повторить')),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final sh = shops[i];
                    final selected = s.shopId == sh['id'];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: SCColors.cream, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('☕', style: TextStyle(fontSize: 24))),
                        ),
                        title: Text(sh['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${sh['address'] ?? ''}\n${sh['opensAt'] ?? ''}–${sh['closesAt'] ?? ''}'
                            '${(sh['isNew'] == true) ? ' · Завтраки до 14:00 🦊' : ''}'),
                        isThreeLine: true,
                        trailing: selected ? const Icon(Icons.check_circle, color: SCColors.matcha) : null,
                        onTap: () {
                          s.setShop(sh['id'] as String, sh['name'] as String);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Выбрана: ${sh['name']}. Меню обновлено.')),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
