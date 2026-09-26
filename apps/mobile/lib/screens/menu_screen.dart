import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';

/// Меню по спеке 3.2: заголовок + кофейня, чипы категорий, ProductTile, CTA корзины.
class MenuScreen extends StatefulWidget {
  final ValueChanged<MenuItem> onOpenProduct;
  const MenuScreen({super.key, required this.onOpenProduct});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool loading = false;
  bool netError = false;

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
    await load();
  }

  Future<void> load() async {
    final s = context.read<Session>();
    if (s.shopId == null) {
      if (mounted) {
        setState(() => netError = true);
      }
      // Витрина без API: мок как в макете
      s.setMenu(MenuItem.mock());
      return;
    }
    if (mounted) setState(() { loading = true; netError = false; });
    try {
      final r = await s.api.dio.get('/menu', queryParameters: {'shopId': s.shopId});
      final items = (r.data as List)
          .map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      s.setMenu(items.isEmpty ? MenuItem.mock() : items);
    } on DioException {
      if (mounted) setState(() => netError = true);
      if (s.menuCache.isEmpty) s.setMenu(MenuItem.mock());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
              children: [
                if (netError) NetErrorBanner(onRetry: load),
                Text('Меню', style: serif(21)),
                GestureDetector(
                  onTap: () {}, // выбор кофейни — на табе Кофейни
                  child: Text('Кофейня на ${s.shopName}',
                      style: sans(11, c: SCColors.muted)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: s.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => CategoryChip(
                      label: s.categories[i],
                      active: s.categories[i] == s.activeCategory,
                      onTap: () => s.setCategory(s.categories[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (loading) const SkeletonList() else ...[
                  for (final m in s.filteredMenu) ...[
                    ProductTile(item: m, onOpen: () => widget.onOpenProduct(m)),
                    const SizedBox(height: 9),
                  ],
                ],
              ],
            ),
            if (s.cartCount > 0)
              Positioned(
                left: 16, right: 16, bottom: 12,
                child: CtaButton(
                  left: 'Корзина · ${s.cartCount}',
                  right: rub(s.cartTotal),
                  onTap: () => Navigator.of(context).pushNamed('/cart'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

