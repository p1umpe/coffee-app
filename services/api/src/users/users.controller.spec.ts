import { NotFoundException } from '@nestjs/common';
import { UsersController } from './users.controller';

// task_0015: DELETE /v1/users/me — моки prisma, без БД.
describe('UsersController.deleteMe', () => {
  const make = (user: any) => {
    const prisma: any = {
      user: { findUnique: jest.fn().mockResolvedValue(user), delete: jest.fn() },
      otpCode: { deleteMany: jest.fn() },
      order: { updateMany: jest.fn() },
      feedback: { deleteMany: jest.fn() },
      $transaction: jest.fn((fn: any) =>
        fn({ user: prisma.user, otpCode: prisma.otpCode, order: prisma.order, feedback: prisma.feedback }),
      ),
    };
    const ctrl = new UsersController(prisma);
    return { ctrl, prisma };
  };

  it('удаляет себя: otp по phone, заказы -> userId=null, фидбеки, user; вернуть {ok:true}', async () => {
    const { ctrl, prisma } = make({ id: 'u1', phone: '79001112233' });
    await expect(ctrl.deleteMe({ user: { sub: 'u1' } })).resolves.toEqual({ ok: true });
    expect(prisma.$transaction).toHaveBeenCalled();
    expect(prisma.otpCode.deleteMany).toHaveBeenCalledWith({ where: { phone: '79001112233' } });
    expect(prisma.order.updateMany).toHaveBeenCalledWith({ where: { userId: 'u1' }, data: { userId: null } });
    expect(prisma.feedback.deleteMany).toHaveBeenCalledWith({ where: { userId: 'u1' } });
    expect(prisma.user.delete).toHaveBeenCalledWith({ where: { id: 'u1' } });
  });

  it('нет пользователя — 404', async () => {
    const { ctrl, prisma } = make(null);
    await expect(ctrl.deleteMe({ user: { sub: 'nope' } })).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
