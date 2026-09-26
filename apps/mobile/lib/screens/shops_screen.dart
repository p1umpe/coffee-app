import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';
import '../widgets/stamp_shop.dart';

/// Кофейни по спеке 3.4: заголовок + город, карта 190/r24 с пинами,
/// ShopTile milk/r18 с плашкой Открыто/Закрыто.
class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});
  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  List<Map<String, dynamic>> shops = [];
  bool loading = true;
  bool netError = false;

  /// Моки как в макете, если API недоступно.
  static const mockPins = [
    {'dx': 60.0, 'dy': 40.0},
    {'dx': 170.0, 'dy': 90.0},
    {'dx': 220.0, 'dy': 30.0},
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = context.read<Session>();
    if (mounted) setState(() { loading = true; netError = false; });
    try {
      final r = await s.api.dio.get('/shops');
      shops = (r.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (shops.isEmpty) throw const FormatException('empty');
    } catch (_) {
      if (mounted) setState(() => netError = true);
      shops = [
        {'id': 'mock-1', 'name': 'Вайнера, 9', 'address': 'Вайнера, 9', 'meta': '300 м · до 22:00', 'open': true},
        {'id': 'mock-2', 'name': 'Ленина, 24', 'address': 'Ленина, 24', 'meta': '650 м · до 21:00', 'open': true},
        {'id': 'mock-3', 'name': 'Малышева, 51', 'address': 'Малышева, 51', 'meta': '1,2 км · до 22:00', 'open': false},
      ];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            if (netError) NetErrorBanner(onRetry: load),
            Text('Кофейни', style: serif(21)),
            Text('Екатеринбург', style: sans(11, c: SCColors.muted)),
            const SizedBox(height: 8),
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: SCColors.mapBg,
                borderRadius: BorderRadius.circular(SCRadii.map),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SCRadii.map),
                child: CustomPaint(
                  painter: _MapGridPainter(),
                  child: Stack(
                    children: [
                      for (int i = 0; i < mockPins.length; i++)
                        Positioned(
                          left: (mockPins[i]['dx'] as double),
                          top: (mockPins[i]['dy'] as double),
                          child: _Pin(
                              highlight: i == 0 &&
                                  (s.shopId == null ||
                                      s.shopId == shops[i]['id'])),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (loading)
              const SkeletonList(count: 3)
            else
              for (final sh in shops) ...[
                ShopTile(
                  name: (sh['name'] ?? '').toString(),
                  address: (sh['address'] ?? sh['name'] ?? '').toString(),
                  meta: (sh['meta'] ??
                          '${sh['opensAt'] ?? '09:00'}–${sh['closesAt'] ?? '22:00'}')
                      .toString(),
                  open: (sh['open'] ?? true) as bool,
                  selected: s.shopId == sh['id'],
                  onTap: () {
                    s.setShop((sh['id'] ?? '').toString(),
                        (sh['name'] ?? '').toString());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Выбрана: ${sh['name']}. Меню обновится 🦊')),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

/// Капля fox с белой точкой, как в макете.
class _Pin extends StatelessWidget {
  final bool highlight;
  const _Pin({this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: highlight ? 32 : 28,
      height: highlight ? 32 : 28,
      decoration: BoxDecoration(
        color: SCColors.fox,
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
          bottomLeft: Radius.circular(50),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 8, height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = SCColors.mapGrid..strokeWidth = 2;
    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

