import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Детали кофейни (task_0010): часы, телефон, маршрут, превью меню.
class ShopDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ShopDetailsScreen({super.key, required this.shop});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  List<MenuItem> preview = [];
  bool loadingMenu = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final s = context.read<Session>();
    final id = (widget.shop['id'] ?? '').toString();
    if (id.startsWith('mock-')) {
      if (mounted) {
        setState(() => preview = MenuItem.mock().take(3).toList());
      }
      return;
    }
    if (mounted) setState(() => loadingMenu = true);
    try {
      final r = await s.api.dio
          .get('/menu', queryParameters: {'shopId': id});
      final items = (r.data as List)
          .map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (mounted) setState(() => preview = items.take(3).toList());
    } on DioException {
      if (mounted) {
        setState(() => preview = MenuItem.mock().take(3).toList());
      }
    } finally {
      if (mounted) setState(() => loadingMenu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final name = (widget.shop['name'] ?? '').toString();
    final address = (widget.shop['address'] ?? name).toString();
    final hours =
        '${widget.shop['opensAt'] ?? '09:00'}–${widget.shop['closesAt'] ?? '22:00'}';
    final phone = (widget.shop['phone'] ?? '+7 (343) 000-00-00').toString();
    final open = (widget.shop['open'] ?? true) as bool;
    final selected = s.shopId == widget.shop['id'];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Row(
              children: [
                const ScBackButton(),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: serif(21))),
              ],
            ),
            const SizedBox(height: 4),
            Text(address, style: sans(12, c: SCColors.muted)),
            const SizedBox(height: 10),
            _info(hours, phone, open),
            const SizedBox(height: 10),
            CtaButton(
              left: 'Маршрут',
              right: '2GIS →',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Маршрут откроется в 2GIS 🦊')),
              ),
            ),
            const SizedBox(height: 14),
            Text('Популярное здесь',
                style: sans(14, w: FontWeight.w700)),
            const SizedBox(height: 8),
            if (loadingMenu)
              const SkeletonList(count: 3)
            else
              for (final m in preview) _dish(s, m),
            const SizedBox(height: 4),
            CtaButton(
              left: selected ? 'Выбрана ✓' : 'Заказать сюда',
              right: '→',
              onTap: open
                  ? () {
                      context.read<Session>().setShop(
                          (widget.shop['id'] ?? '').toString(), name);
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String hours, String phone, bool open) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SCColors.milk,
        borderRadius: BorderRadius.circular(SCRadii.shopCard),
        border: Border.all(color: SCColors.line),
      ),
      child: Column(
        children: [
          _row('🕘', 'Часы', hours),
          const SizedBox(height: 8),
          _row('📞', 'Телефон', phone),
          const SizedBox(height: 8),
          _row('📍', 'Статус', open ? 'Открыто' : 'Закрыто'),
        ],
      ),
    );
  }

  Widget _row(String e, String l, String v) {
    return Row(
      children: [
        Text(e, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(l, style: sans(12, c: SCColors.muted)),
        const Spacer(),
        Text(v, style: sans(12, w: FontWeight.w700)),
      ],
    );
  }

  Widget _dish(Session s, MenuItem m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SCColors.milk,
          borderRadius:
              BorderRadius.circular(SCRadii.productCard),
          border: Border.all(color: SCColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text(m.title,
                    style: sans(13, w: FontWeight.w700))),
            Text(rub(s.priceOf(m)),
                style: sans(13, w: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
