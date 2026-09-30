import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Режим бариста по PIN (P0, task_0006). На моках, без сканера камеры.
/// POST /auth/staff/login, GET /kds/orders?shopId, POST accept|cooking|ready|serve.
/// staffJwt хранится ТОЛЬКО в State, НЕ в Session.api.token.
class BaristaScreen extends StatefulWidget {
  const BaristaScreen({super.key});
  @override
  State<BaristaScreen> createState() => _BaristaScreenState();
}

class _BaristaScreenState extends State<BaristaScreen> {
  late final TextEditingController loginCtrl;
  late final TextEditingController pinCtrl;
  late final TextEditingController shopCtrl;
  final Map<String, TextEditingController> qrCtrls = {};
  late final Dio staffDio;
  String? staffJwt;
  String staffName = '';
  List<dynamic> orders = [];
  bool loggingIn = false;
  bool loadingOrders = false;
  final Set<String> busy = {};
  String? error;
  String? notice;
  bool noAccess = false;
  @override
  void initState() {
    super.initState();
    loginCtrl = TextEditingController(text: 'barista1');
    pinCtrl = TextEditingController(text: '1234');
    shopCtrl = TextEditingController();
    staffDio = Dio(BaseOptions(baseUrl: kApiBase,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = context.read<Session>().shopId;
      if (sid != null && sid.isNotEmpty && mounted) shopCtrl.text = sid;
    });
  }
  @override
  void dispose() {
    loginCtrl.dispose();
    pinCtrl.dispose();
    shopCtrl.dispose();
    for (final c in qrCtrls.values) { c.dispose(); }
    super.dispose();
  }
  TextEditingController qrCtrl(String id) => qrCtrls.putIfAbsent(id, () => TextEditingController());
  Options get auth => Options(headers: {'Authorization': 'Bearer $staffJwt'});
  String errMsg(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) return 'Нет доступа';
    final d = e.response?.data;
    final m = d is Map ? d['message']?.toString() : null;
    if (m != null && m.isNotEmpty) return m;
    return 'Бэк недоступен \u2014 повтори, когда появится сеть';
  }
  Future<void> login() async {
    if (loggingIn) return;
    setState(() { loggingIn = true; error = null; notice = null; noAccess = false; });
    try {
      final res = await staffDio.post('/auth/staff/login', data: {'login': loginCtrl.text.trim(), 'pin': pinCtrl.text.trim()});
      final data = Map<String, dynamic>.from(res.data as Map);
      final token = data['accessToken']?.toString();
      if (token == null || token.isEmpty) { throw DioException(requestOptions: res.requestOptions); }
      final st = data['staff'];
      if (!mounted) return;
      setState(() { staffJwt = token; staffName = st is Map ? (st['name']?.toString() ?? st['login']?.toString() ?? '') : ''; });
      await loadOrders();
    } on DioException catch (e) {
      if (!mounted) return;
      final c = e.response?.statusCode;
      setState(() { noAccess = c == 401 || c == 403; error = errMsg(e); });
    } finally {
      if (mounted) setState(() => loggingIn = false);
    }
  }
  Future<void> loadOrders() async {
    if (staffJwt == null || loadingOrders) return;
    var sid = shopCtrl.text.trim();
    if (sid.isEmpty) sid = context.read<Session>().shopId ?? '';
    if (sid.isEmpty) { setState(() => error = 'Выбери кофейню или введи shopId'); return; }
    if (shopCtrl.text.trim() != sid) shopCtrl.text = sid;
    setState(() { loadingOrders = true; error = null; noAccess = false; });
    try {
      final res = await staffDio.get('/kds/orders', queryParameters: {'shopId': sid}, options: auth);
      final d = res.data;
      final list = d is List ? d : (d is Map && d['orders'] is List ? d['orders'] as List : <dynamic>[]);
      if (!mounted) return;
      setState(() => orders = List<dynamic>.from(list));
    } on DioException catch (e) {
      if (!mounted) return;
      final c = e.response?.statusCode;
      setState(() { noAccess = c == 401 || c == 403; error = errMsg(e); });
    } finally {
      if (mounted) setState(() => loadingOrders = false);
    }
  }
  Future<void> setStatus(String id, String action) async {
    final key = '$id:$action';
    if (busy.contains(key)) return;
    setState(() { busy.add(key); error = null; notice = null; noAccess = false; });
    try {
      await staffDio.post('/kds/orders/$id/$action', options: auth);
      await loadOrders();
    } on DioException catch (e) {
      if (!mounted) return;
      final c = e.response?.statusCode;
      setState(() { noAccess = c == 401 || c == 403; error = errMsg(e); });
    } finally {
      if (mounted) setState(() => busy.remove(key));
    }
  }
  Future<void> serve(String id) async {
    final key = '$id:serve';
    if (busy.contains(key)) return;
    final qr = qrCtrl(id).text.trim();
    if (qr.isEmpty) { setState(() => error = 'Введи QR гостя вручную для выдачи'); return; }
    setState(() { busy.add(key); error = null; notice = null; noAccess = false; });
    try {
      final res = await staffDio.post('/kds/orders/$id/serve', data: {'guestQr': qr}, options: auth);
      int? n;
      final d = res.data;
      if (d is Map) {
        for (final k in ['stampsEarned', 'stampsAdded', 'stamps', 'added', 'earned']) {
          final v = d[k];
          if (v is num) { n = v.toInt(); break; }
        }
      }
      if (!mounted) return;
      setState(() => notice = n != null ? '+$n печатей' : 'Выдано');
      await loadOrders();
    } on DioException catch (e) {
      if (!mounted) return;
      final c = e.response?.statusCode;
      setState(() { noAccess = c == 401 || c == 403; error = errMsg(e); });
    } finally {
      if (mounted) setState(() => busy.remove(key));
    }
  }
  String statusLabel(String s) {
    switch (s) {
      case 'PENDING_PAYMENT': return 'Ожидает оплаты';
      case 'PAID': return 'Оплачен';
      case 'ACCEPTED': return 'Принят';
      case 'COOKING': return 'Готовится';
      case 'READY': return 'Готов';
      case 'SERVED': return 'Выдан';
      case 'CANCELLED': return 'Отменен';
      case 'REFUNDED': return 'Возвращен';
      default: return s;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Режим бариста', style: serif(17))),
      body: SafeArea(child: staffJwt == null ? loginView() : ordersView()));
  }
  Widget loginView() {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      if (noAccess) softBanner('Нет доступа'),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: SCColors.milk, borderRadius: BorderRadius.circular(SCRadii.productCard), border: Border.all(color: SCColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Вход по PIN', style: sans(14, w: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Тестовый: barista1 / 1234', style: sans(11, c: SCColors.muted)),
          const SizedBox(height: 10),
          TextField(controller: loginCtrl, decoration: dec('Логин'), autocorrect: false),
          const SizedBox(height: 8),
          TextField(controller: pinCtrl, decoration: dec('PIN'), obscureText: true, keyboardType: TextInputType.number),
        ])),
      const SizedBox(height: 12),
      CtaButton(left: loggingIn ? 'Входим...' : 'Войти', right: '', onTap: loggingIn ? null : login),
      if (error != null && !noAccess) ...[
        const SizedBox(height: 12),
        NetErrorBanner(onRetry: login),
        const SizedBox(height: 4),
        Text(error!, style: sans(11.5, c: SCColors.muted)),
      ],
    ]);
  }
  Widget ordersView() {
    return RefreshIndicator(onRefresh: loadOrders, color: SCColors.fox,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
        Row(children: [
          Expanded(child: Text(staffName.isEmpty ? 'Смена открыта' : 'Бариста: $staffName', style: sans(13, w: FontWeight.w700))),
          GestureDetector(onTap: () => setState(() { staffJwt = null; orders = []; staffName = ''; error = null; notice = null; noAccess = false; }),
            child: Text('Выйти', style: sans(12, w: FontWeight.w800, c: SCColors.fox))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: shopCtrl, decoration: dec('shopId'), autocorrect: false)),
          const SizedBox(width: 8),
          GestureDetector(onTap: loadingOrders ? null : loadOrders,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: SCColors.espresso, borderRadius: BorderRadius.circular(14)),
              child: Text(loadingOrders ? '...' : 'Обновить', style: sans(12, w: FontWeight.w800, c: SCColors.cream)))),
        ]),
        const SizedBox(height: 8),
        if (noAccess) softBanner('Нет доступа'),
        if (notice != null) ...[
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: SCColors.okBg, borderRadius: BorderRadius.circular(14)),
            child: Text(notice!, style: sans(12.5, c: SCColors.okText, w: FontWeight.w700))),
          const SizedBox(height: 8),
        ],
        if (error != null && !noAccess) ...[
          NetErrorBanner(onRetry: loadOrders),
          const SizedBox(height: 4),
          Text(error!, style: sans(11.5, c: SCColors.muted)),
          const SizedBox(height: 8),
        ],
        if (loadingOrders && orders.isEmpty) const SkeletonList(count: 3)
        else if (orders.isEmpty)
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SCColors.milk, borderRadius: BorderRadius.circular(SCRadii.productCard), border: Border.all(color: SCColors.line)),
            child: Text('Заказов нет \u2014 потяни вниз чтобы обновить', style: sans(12, c: SCColors.muted)))
        else
          for (final o in orders)
            if (o is Map<String, dynamic>) orderCard(o)
            else if (o is Map) orderCard(Map<String, dynamic>.from(o)),
      ]));
  }
  Widget orderCard(Map<String, dynamic> o) {
    final id = o['id']?.toString() ?? '';
    final number = o['number']?.toString() ?? '-';
    final status = o['status']?.toString() ?? '';
    final ful = o['fulfillment']?.toString() ?? '';
    final items = (o['items'] as List?) ?? const [];
    final fulLabel = ful == 'DINE_IN' ? 'В кружке' : ful == 'TAKEAWAY' ? 'С собой' : ful;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SCColors.milk, borderRadius: BorderRadius.circular(SCRadii.productCard), border: Border.all(color: SCColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Заказ $number', style: serif(16))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: SCColors.foxTint, borderRadius: BorderRadius.circular(SCRadii.chip), border: Border.all(color: SCColors.line)),
            child: Text(statusLabel(status), style: sans(11, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 2),
        Text(fulLabel, style: sans(11, c: SCColors.muted)),
        const SizedBox(height: 8),
        for (final it in items)
          if (it is Map)
            Padding(padding: const EdgeInsets.only(bottom: 3),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text((it['title'] ?? it['name'] ?? it['productId'] ?? '...').toString(), style: sans(12))),
                Text('x${(it['qty'] as num?)?.toInt() ?? 1}', style: sans(12, c: SCColors.muted)),
              ])),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [actBtn(id, 'accept', 'Принят'), actBtn(id, 'cooking', 'Готовится'), actBtn(id, 'ready', 'Готов')]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: qrCtrl(id), decoration: dec('QR гостя вручную'), autocorrect: false)),
          const SizedBox(width: 8),
          GestureDetector(onTap: busy.contains('$id:serve') ? null : () => serve(id),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: SCColors.fox, borderRadius: BorderRadius.circular(14)),
              child: Text(busy.contains('$id:serve') ? '...' : 'Выдано', style: sans(12, w: FontWeight.w800, c: Colors.white)))),
        ]),
      ]));
  }
  Widget actBtn(String id, String action, String label) {
    final key = '$id:$action';
    final b = busy.contains(key);
    return GestureDetector(onTap: b ? null : () => setStatus(id, action),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: b ? SCColors.line : SCColors.cream, borderRadius: BorderRadius.circular(SCRadii.chip), border: Border.all(color: SCColors.line)),
        child: Text(b ? '...' : label, style: sans(12, w: FontWeight.w700))));
  }
  Widget softBanner(String t) {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: SCColors.caramel.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: SCColors.caramel.withValues(alpha: 0.5))),
      child: Text(t, style: sans(12, w: FontWeight.w700)));
  }
  InputDecoration dec(String h) {
    return InputDecoration(hintText: h, filled: true, fillColor: SCColors.cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SCColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: SCColors.line)));
  }
}
