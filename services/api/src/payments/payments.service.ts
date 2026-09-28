import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

// Оплата MVP: только КАРТА + СБП (мок-провайдер) + КУПОН (бесплатный кофе) + КАССА.
// Боевой провайдер (CloudPayments/ЮKassa) подключается заменой confirmPayment:
// сейчас confirm сразу SUCCEEDED; в проде — создание payUrl + webhook провайдера.
// Идемпотентность: повторный вызов с тем же idempotencyKey возвращает тот же платёж.
@Injectable()
export class PaymentsService {
  constructor(private prisma: PrismaService, private config: ConfigService) {}

  private providerName() {
    return this.config.get('PAYMENTS_PROVIDER') ?? 'mock';
  }

  async create(orderId: string, method: 'CARD' | 'SBP' | 'COUPON' | 'CASH_DESK', idempotencyKey: string, couponCode?: string) {
    const existed = await this.prisma.payment.findUnique({ where: { idempotencyKey } });
    if (existed) return { ...existed, deduped: true };

    const order = await this.prisma.order.findUnique({ where: { id: orderId }, include: { payments: true } });
    if (!order) throw new BadRequestException('unknown order');
    if (['SERVED', 'CANCELLED', 'REFUNDED'].includes(order.status)) throw new BadRequestException('order closed');

    // Купон: только 1 напиток, гасит total (как раньше в orders.create, но теперь явно через платёж)
    if (method === 'COUPON') {
      if (!couponCode || !order.userId) throw new BadRequestException('coupon needs code + user');
      const coupon = await this.prisma.coupon.findUnique({ where: { code: couponCode } });
      if (!coupon || coupon.isUsed || coupon.userId !== order.userId || coupon.expiresAt < new Date())
        throw new BadRequestException('bad coupon');
      const items = (order.items as any[]) ?? [];
      if (items.length !== 1 || items[0].qty !== 1) throw new BadRequestException('coupon covers exactly 1 drink');
      await this.prisma.coupon.update({ where: { code: couponCode }, data: { isUsed: true } });
      const payment = await this.prisma.payment.create({
        data: { orderId, method: 'COUPON', status: 'SUCCEEDED', amount: 0, provider: 'loyalty', idempotencyKey },
      });
      await this.prisma.order.update({ where: { id: orderId }, data: { status: 'PAID', total: 0 } });
      return payment;
    }

    const amount = order.total;
    if (amount <= 0) throw new BadRequestException('nothing to pay');
    // Если уже есть успешный платёж — не дублируем
    if (order.payments.some((p) => p.status === 'SUCCEEDED')) throw new BadRequestException('already paid');

    const payment = await this.prisma.payment.create({
      data: { orderId, method: method as any, status: 'PENDING', amount, provider: this.providerName(), idempotencyKey },
    });
    return { ...payment, payUrl: null, note: 'mock: вызови /v1/payments/:id/confirm' };
  }

  // Мок-подтверждение: CARD/SBP сразу успешны. В проде сюда придёт webhook провайдера.
  async confirm(paymentId: string, ok = true) {
    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new BadRequestException('unknown payment');
    if (payment.status !== 'PENDING') return payment;
    const status = ok ? 'SUCCEEDED' : 'FAILED';
    const updated = await this.prisma.payment.update({ where: { id: paymentId }, data: { status: status as any } });
    if (ok) {
      await this.prisma.order.update({ where: { id: payment.orderId }, data: { status: 'PAID' } });
    }
    return updated;
  }

  // Webhook провайдера (подпись проверяем, когда подключим боевой PSP)
  async webhook(body: { providerPayId: string; status: string; paymentId?: string }) {
    if (body.paymentId) {
      return this.confirm(body.paymentId, body.status === 'succeeded');
    }
    if (body.providerPayId) {
      const p = await this.prisma.payment.findFirst({ where: { providerPayId: body.providerPayId } });
      if (!p) throw new BadRequestException('unknown provider payment');
      return this.confirm(p.id, body.status === 'succeeded');
    }
    throw new BadRequestException('bad webhook');
  }
}
