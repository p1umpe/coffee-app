import { Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { IikoService } from '../iiko/iiko.service';
import { CreateOrderDto } from './dto';

// Ядро заказа:
// 1) идемпотентность по idempotencyKey (повторный тап = тот же заказ),
// 2) цена зависит от fulfillment: DINE_IN=база, TAKEAWAY=база-дисконт,
// 3) stampsEarned считаем сразу, НАЧИСЛЯЕМ только при выдаче в кружке (loyalty/stamp).
@Injectable()
export class OrdersService {
  constructor(private prisma: PrismaService, private config: ConfigService, private iiko: IikoService) {}

  private async priceFor(shopId: string, productId: string, fulfillment: string) {
    const discount = Number(this.config.get('TAKEAWAY_DISCOUNT') ?? 3000);
    const link = await this.prisma.shopProduct.findUnique({
      where: { shopId_productId: { shopId, productId } },
      include: { product: true },
    });
    if (!link || link.inStopList || !link.product.isActive) throw new BadRequestException(`product ${productId} unavailable`);
    const dineIn = link.dineInPrice ?? link.product.dineInPrice;
    const takeaway = link.takeawayPrice ?? Math.max(0, dineIn - discount);
    return { dineIn, price: fulfillment === 'DINE_IN' ? dineIn : takeaway, givesStamp: link.product.givesStamp };
  }

  async create(dto: CreateOrderDto) {
    // идемпотентность: уже есть такой ключ — вернуть существующий
    const existed = await this.prisma.order.findUnique({ where: { idempotencyKey: dto.idempotencyKey } });
    if (existed) return { ...existed, deduped: true };

    if (!dto.items?.length) throw new BadRequestException('empty items');
    const shop = await this.prisma.shop.findUnique({ where: { id: dto.shopId } });
    if (!shop) throw new BadRequestException('bad shop');

    let total = 0;
    let stampsDue = 0;
    const priced: Array<{ productId: string; qty: number; modifiers: Record<string, unknown>; priceEach: number }> = [];
    for (const it of dto.items) {
      const p = await this.priceFor(dto.shopId, it.productId, dto.fulfillment);
      total += p.price * it.qty;
      if (dto.fulfillment === 'DINE_IN' && p.givesStamp) stampsDue += it.qty; // печати только в кружке
      priced.push({ productId: it.productId, qty: it.qty, modifiers: it.modifiers ?? {}, priceEach: p.price });
    }

    // Оплата бесплатным купоном: гасим total, помечаем купон использованным
    if (dto.couponCode && dto.userId) {
      const coupon = await this.prisma.coupon.findUnique({ where: { code: dto.couponCode } });
      if (!coupon || coupon.isUsed || coupon.userId !== dto.userId || coupon.expiresAt < new Date())
        throw new BadRequestException('bad coupon');
      if (priced.length !== 1 || priced[0].qty !== 1) throw new BadRequestException('coupon covers exactly 1 drink');
      total = 0;
      await this.prisma.coupon.update({ where: { code: dto.couponCode }, data: { isUsed: true } });
    }
    if (total < 0) throw new ConflictException('bad total');

    // Номер А-12: день + счётчик (упрощённо — случайный короткий)
    const number = `А-${Math.floor(10 + Math.random() * 89)}`;

    const order = await this.prisma.order.create({
      data: {
        number,
        shopId: dto.shopId,
        userId: dto.userId ?? null,
        fulfillment: dto.fulfillment as any,
        status: total === 0 ? 'PAID' : 'PENDING_PAYMENT', // купон = уже оплачен
        idempotencyKey: dto.idempotencyKey,
        items: priced as any,
        total,
        stampsEarned: stampsDue,
      },
    });

    // Отправка в iiko (mock сейчас, боевое — когда дашь ключ)
    try {
      const r = await this.iiko.createPickupOrder({ shopIikoId: shop.iikoId, number, items: priced, fulfillment: dto.fulfillment });
      await this.prisma.order.update({ where: { id: order.id }, data: { iikoOrderId: r.iikoOrderId, status: total === 0 ? 'ACCEPTED' : order.status } });
    } catch {
      // не фейлим заказ если кухня недоступна — ретрай позже (упрощённо оставляем PENDING)
    }

    return { ...(await this.prisma.order.findUnique({ where: { id: order.id } })), deduped: false, etaMin: 7 };
  }

  get(id: string) { return this.prisma.order.findUnique({ where: { id } }); }
  byShop(shopId: string) {
    return this.prisma.order.findMany({ where: { shopId }, orderBy: { createdAt: 'desc' }, take: 50 });
  }

  async cancel(id: string) {
    const o = await this.prisma.order.findUnique({ where: { id } });
    if (!o) throw new BadRequestException('not found');
    if (['COOKING', 'READY', 'SERVED'].includes(o.status)) throw new BadRequestException('too late to cancel');
    return this.prisma.order.update({ where: { id }, data: { status: 'CANCELLED' } });
  }

  // Бариста: "Выдано" — закрывает заказ; начисление печатей делает LoyaltyService (чтобы не дублировать)
  async markServed(id: string) {
    return this.prisma.order.update({ where: { id }, data: { status: 'SERVED' } });
  }
}
