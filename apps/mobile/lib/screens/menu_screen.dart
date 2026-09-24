import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ensureShopAndLoad());
  }

  Future<void> ensureShopAndLoad() async {
    final s = context.read<Session>();
    if (s.shopId == null) {
      try {
        final r = await s.api.dio.get('/shops');
        final list = (r.data as List);
        if (list.isNotEmpty) {
          final first = Map<String, dynamic>.from(list.first as Map);
          s.setShop(first['id'] as String, first['name'] as String);
        }
      } catch (_) {}
    }
    load();
  }

  Future<void> load() async {
    final s = context.read<Session>();
    if (s.shopId == null) {
      setState(() => error = 'Выбери кофейню во вкладке «Кофейни»');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final r = await s.api.dio.get('/menu', queryParameters: {'shopId': s.shopId});
      s.menuCache = (r.data as List)
          .map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() {});
    } on DioException {
      setState(() => error = 'Нет связи с API :3000. Бэк запущен?');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simple Coffee', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(s.shopName, style: const TextStyle(fontSize: 12, color: SCColors.secondary)),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: load)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SegmentedButton<Fulfillment>(
                      segments: const [
                        ButtonSegment(value: Fulfillment.dineIn, label: Text('В кружке 🍵')),
                        ButtonSegment(value: Fulfillment.takeaway, label: Text('С собой 🥤')),
                      ],
                      selected: {s.fulfillment},
                      onSelectionChanged: (v) => s.setFulfillment(v.first),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.fulfillment == Fulfillment.dineIn
                          ? 'Базовая цена · +${s.cartStampsDue} печати за корзину 🦊'
                          : 'Дешевле на ~30 ₽ · без печатей',
                      style: const TextStyle(fontSize: 13, color: SCColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _body(s)),
        ],
      ),
    );
  }

  Widget _body(Session s) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error!), const SizedBox(height: 8),
        FilledButton(onPressed: load, child: const Text('Повторить')),
      ]));
    }
    if (s.menuCache.isEmpty) {
      return const Center(child: Text('Меню пустое — проверь стоп-лист'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: s.menuCache.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => ProductCard(item: s.menuCache[i]),
    );
  }
}
