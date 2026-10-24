import { ConflictException } from '@nestjs/common';
import { OrdersService } from './orders.service';

// C3: при коллизии номера заказа (P2002 по number) сервис ретраит с новым номером.
describe('OrdersService.create: ретрай номера заказа', () => {
  const p2002 = (field: string) =>
    Object.assign(new Error('Unique constraint failed'), { code: 'P2002', meta: { target: [field] } });

  const make = (createImpl: jest.Mock) => {
    const prisma: any = {
      order: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: createImpl,
        update: jest.fn().mockResolvedValue({}),
      },
      shop: { findUnique: jest.fn().mockResolvedValue({ id: 's1', iikoId: null }) },
      shopProduct: {
        findUnique: jest.fn().mockResolvedValue({
          inStopList: false, dineInPrice: null, takeawayPrice: null,
          product: { isActive: true, dineInPrice: 32000, givesStamp: true },
        }),
      },
      coupon: { findUnique: jest.fn(), update: jest.fn() },
    };
    const config: any = { get: () => undefined };
    const iiko: any = { createPickupOrder: jest.fn().mockResolvedValue({ iikoOrderId: 'm1' }) };
    return { svc: new OrdersService(prisma, config, iiko), prisma };
  };

  const dto: any = {
    shopId: 's1', fulfillment: 'DINE_IN', idempotencyKey: 'key-12345678',
    items: [{ productId: 'p1', qty: 1 }],
  };

  it('первый create падает с P2002(number), второй проходит с новым номером', async () => {
    const create = jest.fn()
      .mockRejectedValueOnce(p2002('number'))
      .mockImplementationOnce(async ({ data }: any) => ({ id: 'o1', ...data }));
    const { svc } = make(create);

    await expect(svc.create(dto)).resolves.toBeDefined();
    expect(create).toHaveBeenCalledTimes(2);
    const n1 = create.mock.calls[0][0].data.number;
    expect(n1).toMatch(/^А-\d{3}$/);
    expect(create.mock.calls[1][0].data.number).toMatch(/^А-\d{3}$/);
  });

  it('5 коллизий подряд: ConflictException, не сырая ошибка Prisma', async () => {
    const create = jest.fn().mockRejectedValue(p2002('number'));
    const { svc } = make(create);

    await expect(svc.create(dto)).rejects.toBeInstanceOf(ConflictException);
    expect(create).toHaveBeenCalledTimes(5);
  });

  it('прочие ошибки не ретраим', async () => {
    const create = jest.fn().mockRejectedValue(new Error('db down'));
    const { svc } = make(create);

    await expect(svc.create(dto)).rejects.toThrow('db down');
    expect(create).toHaveBeenCalledTimes(1);
  });

  it('гонка по idempotencyKey: возвращаем существующий заказ', async () => {
    const create = jest.fn().mockRejectedValue(p2002('idempotencyKey'));
    const { svc, prisma } = make(create);
    prisma.order.findUnique
      .mockResolvedValueOnce(null) // проверка в начале create
      .mockResolvedValueOnce({ id: 'o-existing', idempotencyKey: dto.idempotencyKey });

    const r: any = await svc.create(dto);
    expect(r.id).toBe('o-existing');
    expect(r.deduped).toBe(true);
    expect(create).toHaveBeenCalledTimes(1);
  });
});