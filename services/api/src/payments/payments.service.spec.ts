import { PaymentsService } from './payments.service';

// task_0008: refund — моки prisma, без БД.
describe('PaymentsService.refund', () => {
  const make = (over: any) => {
    const prisma: any = {
      payment: { findUnique: jest.fn(), update: jest.fn() },
      order: { findUnique: jest.fn(), update: jest.fn() },
      $transaction: jest.fn((fn: any) => fn({ payment: prisma.payment, order: prisma.order })),
    };
    prisma.payment.findUnique.mockResolvedValue(over.payment);
    prisma.order.findUnique.mockResolvedValue(over.order);
    prisma.payment.update.mockImplementation(async ({ data }: any) => ({ ...over.payment, ...data }));
    const svc = new PaymentsService(prisma, { get: () => 'mock' } as any);
    return { svc, prisma };
  };

  it('уже REFUNDED — вернуть как есть (идемпотентность)', async () => {
    const { svc, prisma } = make({ payment: { id: 'p1', orderId: 'o1', status: 'REFUNDED' }, order: null });
    const r: any = await svc.refund('p1');
    expect(r.status).toBe('REFUNDED');
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('PENDING/FAILED — 400', async () => {
    for (const s of ['PENDING', 'FAILED']) {
      const { svc } = make({ payment: { id: 'p1', orderId: 'o1', status: s }, order: { id: 'o1', status: 'PAID' } });
      await expect(svc.refund('p1')).rejects.toThrow('nothing to refund');
    }
  });

  it('заказ COOKING/READY/SERVED — 400 too late', async () => {
    for (const s of ['COOKING', 'READY', 'SERVED']) {
      const { svc } = make({ payment: { id: 'p1', orderId: 'o1', status: 'SUCCEEDED' }, order: { id: 'o1', status: s } });
      await expect(svc.refund('p1')).rejects.toThrow('too late');
    }
  });

  it('SUCCEEDED + PAID — транзакция payment+order REFUNDED', async () => {
    const { svc, prisma } = make({ payment: { id: 'p1', orderId: 'o1', status: 'SUCCEEDED' }, order: { id: 'o1', status: 'PAID' } });
    const r: any = await svc.refund('p1');
    expect(r.status).toBe('REFUNDED');
    expect(prisma.$transaction).toHaveBeenCalled();
    expect(prisma.payment.update).toHaveBeenCalledWith({ where: { id: 'p1' }, data: { status: 'REFUNDED' } });
    expect(prisma.order.update).toHaveBeenCalledWith({ where: { id: 'o1' }, data: { status: 'REFUNDED' } });
  });
});
