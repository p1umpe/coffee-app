import { OrdersService } from './orders.service';
import { PaymentsService } from '../payments/payments.service';

jest.mock('nanoid', () => ({
  customAlphabet: () => () => 'ABC123',
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { LoyaltyService } = require('../loyalty/loyalty.service');

// task_0016: E2E пути B на моках (без БД и сети).
// Путь: заказ DINE_IN → оплата CARD+confirm (PAID)
// → КДС accept/cooking/ready → serve (+печати) → повтор отклонён.
describe('E2E путь B (моки prisma)', () => {
  const products: Record<string, any> = {
    cap: { id: 'cap', dineInPrice: 32000, givesStamp: true, isActive: true },
    cake: { id: 'cake', dineInPrice: 18000, givesStamp: false, isActive: true },
  };
  const db: any = { orders: {}, payments: {}, users: {}, coupons: [] };

  const prisma: any = {
    shopProduct: {
      findUnique: jest.fn(async ({ where }: any) => {
        const p = products[where.shopId_productId.productId];
        if (!p) return null;
        return { ...p, inStopList: false, product: p, dineInPrice: null, takeawayPrice: null };
      }),
    },
    shop: { findUnique: jest.fn(async () => ({ id: 'shop1', iikoId: null })) },
    order: {
      findUnique: jest.fn(async ({ where, include }: any) => {
        const o: any = Object.values(db.orders).find(
          (x: any) => x.id === where.id || x.idempotencyKey === where.idempotencyKey,
        ) ?? null;
        if (o && include?.payments) o.payments = Object.values(db.payments).filter((p: any) => p.orderId === o.id);
        return o;
      }),
      create: jest.fn(async ({ data }: any) => {
        const o = { ...data, id: `o${Object.keys(db.orders).length + 1}` };
        db.orders[o.id] = o;
        return o;
      }),
      update: jest.fn(async ({ where, data }: any) => {
        db.orders[where.id] = { ...db.orders[where.id], ...data };
        return db.orders[where.id];
      }),
    },
    payment: {
      findUnique: jest.fn(async ({ where }: any) =>
        Object.values(db.payments).find(
          (p: any) => p.id === where.id || p.idempotencyKey === where.idempotencyKey,
        ) ?? null),
      create: jest.fn(async ({ data }: any) => {
        const p = { ...data, id: `p${Object.keys(db.payments).length + 1}` };
        db.payments[p.id] = p;
        return p;
      }),
      update: jest.fn(async ({ where, data }: any) => {
        db.payments[where.id] = { ...db.payments[where.id], ...data };
        return db.payments[where.id];
      }),
    },
    user: {
      findUnique: jest.fn(async ({ where }: any) =>
        Object.values(db.users).find(
          (u: any) => u.id === where.id || u.guestQr === where.guestQr,
        ) ?? null),
      update: jest.fn(async ({ where, data }: any) => {
        db.users[where.id] = { ...db.users[where.id], ...data };
        return db.users[where.id];
      }),
    },
    coupon: {
      findUnique: jest.fn(),
      create: jest.fn(async ({ data }: any) => {
        const c = { ...data, id: `c${db.coupons.length + 1}` };
        db.coupons.push(c);
        return c;
      }),
    },
    $transaction: jest.fn((fn: any) => fn(prisma)),
  };

  const config: any = { get: (k: string) =>
    ({ TAKEAWAY_DISCOUNT: 3000, STAMPS_TO_FREE_CUP: 6, FREE_CUP_TTL_DAYS: 30 } as any)[k] };
  const iiko: any = { createPickupOrder: jest.fn(async () => ({ iikoOrderId: 'm1', etaMin: 7 })) };

  const orders = new OrdersService(prisma, config, iiko);
  const payments = new PaymentsService(prisma, config);
  const loyalty = new LoyaltyService(prisma, config);

  beforeEach(() => {
    db.orders = {}; db.payments = {}; db.coupons = [];
    db.users = { u1: { id: 'u1', guestQr: 'qr1', stamps: 0 } };
  });

  it('DINE_IN: заказ → оплата → КДС → serve, повтор отклонён', async () => {
    const o: any = await orders.create({
      shopId: 'shop1', fulfillment: 'DINE_IN' as any, userId: 'u1',
      idempotencyKey: 'k1', items: [{ productId: 'cap', qty: 1 }],
    } as any);
    expect(o.total).toBe(32000);
    expect(o.stampsEarned).toBe(1);

    const p: any = await payments.create(o.id, 'CARD', 'pk1');
    const pc: any = await payments.confirm(p.id, true);
    expect(pc.status).toBe('SUCCEEDED');
    expect(db.orders[o.id].status).toBe('PAID');

    for (const st of ['ACCEPTED', 'COOKING', 'READY']) {
      await prisma.order.update({ where: { id: o.id }, data: { status: st } });
    }
    expect(db.orders[o.id].status).toBe('READY');

    const s: any = await loyalty.stamp(o.id, 'qr1');
    expect(s.added).toBe(1);
    expect(s.stamps).toBe(1);
    await expect(loyalty.stamp(o.id, 'qr1')).rejects.toThrow('already stamped');
  });

  it('TAKEAWAY: напитки −3000, еда без скидки, печатей 0', async () => {
    const o: any = await orders.create({
      shopId: 'shop1', fulfillment: 'TAKEAWAY' as any, userId: 'u1',
      idempotencyKey: 'k2',
      items: [{ productId: 'cap', qty: 1 }, { productId: 'cake', qty: 1 }],
    } as any);
    expect(o.total).toBe(47000);
    expect(o.stampsEarned).toBe(0);
    await expect(loyalty.stamp(o.id, 'qr1')).rejects.toThrow();
  });

  it('6 печатей = купон на 7-й', async () => {
    db.users.u1.stamps = 5;
    const o: any = await orders.create({
      shopId: 'shop1', fulfillment: 'DINE_IN' as any, userId: 'u1',
      idempotencyKey: 'k3', items: [{ productId: 'cap', qty: 1 }],
    } as any);
    const s: any = await loyalty.stamp(o.id, 'qr1');
    expect(s.newCoupons.length).toBe(1);
    expect(s.stamps).toBe(0);
  });
});
