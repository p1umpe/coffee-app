import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { customAlphabet } from 'nanoid';

// Механика «Кружка = печать»:
// - stamp(orderId, guestQr): бариста сканирует QR гостя при выдаче В КРУЖКЕ.
//   Начисляем min(stampsEarned, напитков), при достижении STAMPS_TO_FREE_CUP выдаём купон.
// - TAKEAWAY заказы печатей не дают (stampsEarned=0) — защита на уровне orders.service.
@Injectable()
export class LoyaltyService {
  constructor(private prisma: PrismaService, private config: ConfigService) {}

  me(userId: string) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      include: { coupons: { where: { isUsed: false }, orderBy: { expiresAt: 'asc' } } },
    });
  }

  async stamp(orderId: string, guestQr: string) {
    const need = Number(this.config.get('STAMPS_TO_FREE_CUP') ?? 6);
    const ttlDays = Number(this.config.get('FREE_CUP_TTL_DAYS') ?? 30);

    const user = await this.prisma.user.findUnique({ where: { guestQr } });
    if (!user) throw new BadRequestException('unknown guest QR');

    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new BadRequestException('unknown order');
    if (order.fulfillment !== 'DINE_IN') throw new BadRequestException('takeaway gives no stamps');
    if (order.status === 'SERVED') throw new BadRequestException('already stamped'); // одна выдача = одно начисление
    if ((order.stampsEarned ?? 0) <= 0) throw new BadRequestException('nothing to stamp');

    // В одной транзакции: заказ SERVED + печати + купон при переполнении
    const result = await this.prisma.$transaction(async (tx) => {
      await tx.order.update({ where: { id: orderId }, data: { status: 'SERVED', userId: user.id } });
      let stamps = user.stamps + order.stampsEarned;
      let coupons: string[] = [];
      while (stamps >= need) {
        stamps -= need;
        const code = `FREECUP-${customAlphabet('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 6)()}`;
        await tx.coupon.create({
          data: { userId: user.id, code, expiresAt: new Date(Date.now() + ttlDays * 86400_000) },
        });
        coupons.push(code);
      }
      const updated = await tx.user.update({ where: { id: user.id }, data: { stamps } });
      return { stamps: updated.stamps, newCoupons: coupons };
    });
    return { ok: true, added: order.stampsEarned, ...result };
  }
}
