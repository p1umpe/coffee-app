import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../core/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/common.dart';
import 'order_status_screen.dart';

/// Экран оплаты (P0, task_0003). Работа на моках, без PSP SDK.
/// Флоу: POST /orders (uuid) -> POST /payments -> POST /payments/:id/confirm.
/// CASH_DESK: payments пропускаем, сразу успех «Оплата в кофейне».
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum PayMethod { card, sbp, coupon, cashDesk }

extension PayMethodApi on PayMethod {
  String get api {
    switch (this) {
      case PayMethod.card:
        return 'CARD';
      case PayMethod.sbp:
        return 'SBP';
      case PayMethod.coupon:
        return 'COUPON';
      case PayMethod.cashDesk:
        return 'CASH_DESK';
    }
  }
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PayMethod method = PayMethod.card;
  final couponCtrl = TextEditingController();
  bool busy = false;
  String? error;
  String? success;

  @override
  void initState() {
    super.initState();
    // Купон, применённый из экрана «Мои купоны»
    final code = context.read<Session>().appliedCouponCode;
    if (code != null && code.isNotEmpty) {
      couponCtrl.text = code;
      method = PayMethod.coupon;
    }
  }

  @override
  void dispose() {
    couponCtrl.dispose();
    super.dispose();
  }

  String errMsg(DioException e) {
    final msg = e.response?.data?['message'];
    if (msg is String && msg.isNotEmpty) return msg;
    return 'Бэк недоступен — повтори, когда появится сеть';
  }

  Future<void> pay() async {
    final s = context.read<Session>();
    if (s.shopId == null || s.userId == null || s.cart.isEmpty || busy) return;
    if (method == PayMethod.coupon && couponCtrl.text.trim().isEmpty) {
      setState(() => error = 'Введи код купона');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      success = null;
    });
    try {
      final orderRes = await s.api.dio.post('/orders', data: {
        'shopId': s.shopId,
        'fulfillment': s.fulfillment.api,
        'userId': s.userId,
        'idempotencyKey': const Uuid().v4(),
        'items': s.cart.entries
            .map((e) => {'productId': e.key, 'qty': e.value})
            .toList(),
      });
      final order = orderRes.data as Map<String, dynamic>;
      final orderId = order['id'] as String;
      final number = order['number']?.toString() ?? 'А-??';
      final eta = order['etaMin'] ?? 7;
      if (method == PayMethod.cashDesk) {
        if (!mounted) return;
        setState(() => success = 'Заказ $number · ~$eta мин · Оплата в кофейне');
        final doneId = orderId;
        s.clearCart();
        await s.refreshLoyalty();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: doneId)),
        );
        return;
      }
      final payRes = await s.api.dio.post('/payments', data: {
        'orderId': orderId,
        'method': method.api,
        'idempotencyKey': const Uuid().v4(),
        if (method == PayMethod.coupon) 'couponCode': couponCtrl.text.trim(),
      });
      final payment = payRes.data as Map<String, dynamic>;
      final paymentId = payment['id'] as String?;
      if (paymentId != null && payment['status'] == 'PENDING') {
        await s.api.dio.post('/payments/$paymentId/confirm', data: {'ok': true});
      }
      // Купон использован — сбрасываем выбор
      s.clearCoupon();
      if (!mounted) return;
      setState(() => success = 'Заказ $number · ~$eta мин');
      final doneId = orderId;
      s.clearCart();
      await s.refreshLoyalty();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: doneId)),
      );
    } on DioException catch (e) {
      if (mounted) setState(() => error = errMsg(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final s = context.watch<Session>();
    final hint = s.fulfillment == Fulfillment.dineIn
        ? 'В кружке · +${s.cartStampsDue} печати'
        : 'С собой · напитки −30 ₽ · без печатей';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            Row(
              children: [
                const ScBackButton(),
                const SizedBox(width: 10),
                Text('Оплата', style: serif(21)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Кофейня на ${s.shopName}', style: sans(11, c: SCColors.muted)),
            const SizedBox(height: 10),
            mRow(PayMethod.card, 'Карта', 'Мок-подтверждение'),
            const SizedBox(height: 8),
            mRow(PayMethod.sbp, 'СБП', 'Мок-подтверждение'),
            const SizedBox(height: 8),
            mRow(PayMethod.coupon, 'Купон', 'Бесплатный кофе'),
            const SizedBox(height: 8),
            mRow(PayMethod.cashDesk, 'В кофейне', 'Оплата на кассе'),
            if (method == PayMethod.coupon) ...[
              const SizedBox(height: 10),
              TextField(
                controller: couponCtrl,
                decoration: InputDecoration(
                  hintText: 'Код купона',
                  filled: true,
                  fillColor: SCColors.milk,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SCColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SCColors.line),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SCColors.milk,
                borderRadius: BorderRadius.circular(SCRadii.productCard),
                border: Border.all(color: SCColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Итого', style: sans(13, w: FontWeight.w700)),
                      Text(rub(s.cartTotal), style: sans(15, w: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(hint, style: sans(11, c: SCColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CtaButton(
              left: busy ? 'Оплачиваем…' : 'Оплатить',
              right: rub(s.cartTotal),
              onTap: busy || s.cart.isEmpty ? null : pay,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              NetErrorBanner(onRetry: pay),
              const SizedBox(height: 4),
              Text(error!, style: sans(11.5, c: SCColors.muted)),
            ],
            if (success != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: SCColors.okBg, borderRadius: BorderRadius.circular(14)),
                child: Text(success!, style: sans(12.5, c: SCColors.okText)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget mRow(PayMethod m, String title, String sub) {
    final on = method == m;
    return GestureDetector(
      onTap: busy ? null : () => setState(() => method = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: on ? SCColors.foxTint : SCColors.milk,
          borderRadius: BorderRadius.circular(SCRadii.productCard),
          border: Border.all(
              color: on ? SCColors.fox : SCColors.line, width: on ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: sans(13,
                          w: FontWeight.w700,
                          c: on ? SCColors.fox : SCColors.espresso)),
                  Text(sub, style: sans(10.5, c: SCColors.muted)),
                ],
              ),
            ),
            if (on)
              const Icon(Icons.check_circle, color: SCColors.fox, size: 20),
          ],
        ),
      ),
    );
  }
}
