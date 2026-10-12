import { Controller, Delete, NotFoundException, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { PrismaService } from '../prisma/prisma.service';

// task_0015: удаление аккаунта гостя (GDPR «право на забвение»).
// DELETE /v1/users/me (глобальный префикс v1 задан в main.ts).
// В транзакции: чистим OtpCode по phone, отвязываем заказы (userId=null,
// остаются как анонимные для аналитики), удаляем фидбеки (в схеме без
// onDelete — чистим явно), удаляем user (каскад сносит купоны).
@Controller('users')
@UseGuards(JwtGuard)
export class UsersController {
  constructor(private prisma: PrismaService) {}

  @Delete('me')
  async deleteMe(@Req() req: any) {
    const userId: string = req.user?.sub;
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('user not found');

    await this.prisma.$transaction(async (tx) => {
      await tx.otpCode.deleteMany({ where: { phone: user.phone } });
      await tx.order.updateMany({ where: { userId }, data: { userId: null } });
      await tx.feedback.deleteMany({ where: { userId } });
      await tx.user.delete({ where: { id: userId } });
    });

    return { ok: true };
  }
}
