import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';

/// Статус заказа (P0, task_0004). Моки, без push.
/// Polling GET /orders/:id каждые 5 сек, Timer отменяется в dispose.
class OrderStatusScreen extends StatefulWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});
  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Map<String, dynamic>? order;
  bool firstLoading = true;
  String? error;
  Timer? timer;
  bool pickedUp = false;
  bool fetching = false;
  static const steps = ['Принят', 'Готовится', 'Готов', 'Выдан'];

  int statusIndex(String s) {
    switch (s) {
      case 'PAID':
      case 'ACCEPTED':
        return 0;
      case 'COOKING':
        return 1;
      case 'READY':
        return 2;
      case 'SERVED':
        return 3;
      default:
        return -1;
    }
  }

  bool get isTerminal {
    final s = order?['status']?.toString() ?? '';
    return s == 'SERVED' || s == 'CANCELLED' || s == 'REFUNDED';
  }

  String statusLabel(String s) {
    switch (s) {
      case 'PENDING_PAYMENT':
        return 'Ожидает оплаты';
      case 'PAID':
        return 'Оплачен';
      case 'ACCEPTED':
        return 'Принят';
      case 'COOKING':
        return 'Готовится';
      case 'READY':
        return 'Готов \u2014 забирай!';
      case 'SERVED':
        return 'Выдан';
      case 'CANCELLED':
        return 'Отменён';
      case 'REFUNDED':
        return 'Возвращён';
      default:
        return s;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrder();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchOrder());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrder() async {
    if (fetching) return;
    fetching = true;
    try {
      final dio = context.read<Session>().api.dio;
      final res = await dio.get('/orders/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        order = Map<String, dynamic>.from(res.data as Map);
        error = null;
        firstLoading = false;
      });
      if (isTerminal) timer?.cancel();
    } on DioException catch (e) {
      if (!mounted) return;
      final d = e.response?.data;
      final msg = d is Map ? d['message']?.toString() : null;
      setState(() {
        error = (msg != null && msg.isNotEmpty) ? msg : 'Бэк недоступен \u2014 повтори, когда появится сеть';
        firstLoading = false;
      });
    } finally {
      fetching = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    final status = order?['status']?.toString() ?? 'PENDING_PAYMENT';
    final number = order?['number']?.toString() ?? 'А-…';
    final eta = order?['etaMin'] ?? 7;
    final fulfillment = order?['fulfillment']?.toString() ?? '';
    final total = (order?['total'] as num?)?.toInt();
    final stamps = (order?['stampsEarned'] as num?)?.toInt() ?? 0;
    final items = (order?['items'] as List?) ?? const [];
    final idx = statusIndex(status);
    final cancelled = status == 'CANCELLED' || status == 'REFUNDED';
    return Scaffold(
      appBar: AppBar(title: Text('Статус заказа', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            if (firstLoading && order == null)
              const SkeletonList(count: 4)
            else ...[
              _Head(
                number: number, eta: eta, status: statusLabel(status),
                fulfillment: fulfillment, total: total, stamps: stamps,
              ),
              const SizedBox(height: 12),
              if (cancelled)
                _CancelBox(cancelled: status == 'CANCELLED')
              else
                TrackerSteps(steps: steps, active: idx),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Состав', style: sans(13, w: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final e in items)
                  _ItemRow(m: Map<String, dynamic>.from((e as Map?) ?? const {})),
              ],
              const SizedBox(height: 16),
              if (!cancelled && !pickedUp)
                CtaButton(left: 'Я забрал', right: '›', onTap: () => setState(() => pickedUp = true))
              else if (pickedUp)
                const _PickedBox(),
              if (status == 'SERVED') ...[
                const SizedBox(height: 12),
                _RateCard(
                  orderId: widget.orderId,
                  rated: (order?['rating'] as num?)?.toInt(),
                ),
              ],
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              NetErrorBanner(onRetry: fetchOrder),
              const SizedBox(height: 4),
              Text(error!, style: sans(11.5, c: SCColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}
class _Head extends StatelessWidget {
  final String number; final Object eta; final String status;
  final String fulfillment; final int? total; final int stamps;
  const _Head({required this.number, required this.eta, required this.status, required this.fulfillment, required this.total, required this.stamps});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SCColors.milk, borderRadius: BorderRadius.circular(SCRadii.productCard), border: Border.all(color: SCColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(number, style: serif(21)),
        const SizedBox(height: 4),
        Text('~$eta мин \u00b7 $status', style: sans(12.5, c: SCColors.muted)),
        if (fulfillment.isNotEmpty) Text(fulfillment == 'DINE_IN' ? 'В кружке' : 'С собой', style: sans(11.5, c: SCColors.muted)),
        if (total != null) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Итого', style: sans(13, w: FontWeight.w700)),
            Text(rub(total!), style: sans(15, w: FontWeight.w800)),
          ]),
        ],
        if (stamps > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text('+$stamps печати', style: sans(11.5, c: SCColors.okText, w: FontWeight.w700))),
      ]),
    );
  }
}

class _CancelBox extends StatelessWidget {
  final bool cancelled;
  const _CancelBox({required this.cancelled});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SCColors.caramel.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: SCColors.caramel.withValues(alpha: 0.5))),
      child: Text(cancelled ? 'Заказ отменён. Деньги вернутся по правилам оплаты.' : 'Заказ возвращён.', style: sans(12.5)),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> m;
  const _ItemRow({required this.m});
  @override
  Widget build(BuildContext context) {
    final qty = (m['qty'] as num?)?.toInt() ?? 1;
    final pid = m['productId']?.toString() ?? '...';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(pid, style: sans(12))),
          Text('x$qty', style: sans(12, c: SCColors.muted)),
        ],
      ),
    );
  }
}

class _PickedBox extends StatelessWidget {
  const _PickedBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SCColors.okBg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.check_circle, color: SCColors.okText, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('Приятного кофе!', style: sans(12.5, c: SCColors.okText, w: FontWeight.w700))),
      ]),
    );
  }
}
/// Горизонтальный трекер: точка + подпись, пройденные \u2014 fox.
class TrackerSteps extends StatelessWidget {
  final List<String> steps;
  final int active;
  const TrackerSteps({super.key, required this.steps, required this.active});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: SCColors.milk, borderRadius: BorderRadius.circular(SCRadii.productCard), border: Border.all(color: SCColors.line)),
      child: Row(children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(child: _Step(label: steps[i], done: i < active || (active == 3 && i == 3), current: i == active)),
          if (i != steps.length - 1) Container(height: 2, width: 12, margin: const EdgeInsets.only(bottom: 18), color: i < active ? SCColors.fox : SCColors.line),
        ],
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String label; final bool done; final bool current;
  const _Step({required this.label, required this.done, required this.current});
  @override
  Widget build(BuildContext context) {
    final Color dot = done || current ? SCColors.fox : SCColors.line;
    return Column(children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: current ? SCColors.foxTint : (done ? SCColors.fox : SCColors.milk), shape: BoxShape.circle, border: Border.all(color: dot, width: 1.5)),
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 15)
            : current
                ? Container(margin: const EdgeInsets.all(7), decoration: const BoxDecoration(color: SCColors.fox, shape: BoxShape.circle))
                : null,
      ),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: sans(10, w: current ? FontWeight.w800 : FontWeight.w600, c: (done || current) ? SCColors.espresso : SCColors.muted)),
    ]);
  }
}

/// Оценка заказа (task_0012): 5 лисичек + комментарий, POST /orders/:id/rate.
/// Показывается 1 раз на SERVED-заказ; если rating уже есть — «Спасибо!».
class _RateCard extends StatefulWidget {
  final String orderId;
  final int? rated;
  const _RateCard({required this.orderId, this.rated});

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  int stars = 0;
  final commentCtrl = TextEditingController();
  bool busy = false;
  bool done = false;
  String? error;

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (stars < 1 || busy) return;
    setState(() { busy = true; error = null; });
    try {
      await context.read<Session>().api.dio.post(
        '/orders/${widget.orderId}/rate',
        data: {
          'rating': stars,
          if (commentCtrl.text.trim().isNotEmpty)
            'comment': commentCtrl.text.trim(),
        },
      );
      if (mounted) setState(() => done = true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (mounted) {
        setState(() => error = msg is String ? msg : 'Не отправилось — попробуй позже');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (done || (widget.rated != null && widget.rated! > 0)) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: SCColors.okBg, borderRadius: BorderRadius.circular(14)),
        child: Text('Спасибо за оценку! Приходи ещё 🦊',
            style: sans(12.5, c: SCColors.okText, w: FontWeight.w700)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SCColors.milk,
        borderRadius: BorderRadius.circular(SCRadii.productCard),
        border: Border.all(color: SCColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Как тебе кофе? 🦊', style: sans(13, w: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final on = i < stars;
              return GestureDetector(
                onTap: busy ? null : () => setState(() => stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(on ? '🦊' : '◯',
                      style: TextStyle(fontSize: 30, color: on ? SCColors.fox : SCColors.line)),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: commentCtrl,
            maxLines: 2,
            maxLength: 500,
            style: sans(13),
            decoration: InputDecoration(
              hintText: 'Комментарий (необязательно)',
              hintStyle: sans(12, c: SCColors.muted),
              filled: true,
              fillColor: SCColors.cream,
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SCColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SCColors.fox, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          CtaButton(
            left: busy ? 'Отправляем…' : 'Оценить',
            right: stars > 0 ? '$stars/5' : '—',
            onTap: busy || stars < 1 ? null : send,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: sans(11.5, c: SCColors.muted)),
          ],
        ],
      ),
    );
  }
}
