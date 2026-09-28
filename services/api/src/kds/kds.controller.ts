import { Controller, Get, Param, Post, Body, UseGuards, Req, ForbiddenException, Query } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LoyaltyService } from '../loyalty/loyalty.service';
import { JwtGuard } from '../auth/jwt.guard';

// КДС-лайт в том же приложении: вход по PIN даёт JWT role=staff,
// все ручки требуют staff JWT. Лента точки, статусы, выдача в кружке со сканом.
@Controller('kds')
@UseGuards(JwtGuard)
export class KdsController {
  constructor(private prisma: PrismaService, private loyalty: LoyaltyService) {}

  private needStaff(req: any) {
    if (req.user?.role !== 'staff') throw new ForbiddenException('staff only');
    return req.user as { sub: string; shopId?: string; staffRole?: string };
  }

  // Лента заказов: ?shopId=... или своя точка бариста из JWT
  @Get('orders')
  feed(@Req() req: any, @Query('shopId') shopId?: string) {
    const me = this.needStaff(req);
    const sid = shopId ?? me.shopId;
    const where = sid ? { shopId: sid } : {};
    return this.prisma.order.findMany({ where, orderBy: { createdAt: 'desc' }, take: 50 });
  }

  @Post('orders/:id/accept') accept(@Req() req: any, @Param('id') id: string) {
    this.needStaff(req);
    return this.prisma.order.update({ where: { id }, data: { status: 'ACCEPTED' } });
  }

  @Post('orders/:id/cooking') cooking(@Req() req: any, @Param('id') id: string) {
    this.needStaff(req);
    return this.prisma.order.update({ where: { id }, data: { status: 'COOKING' } });
  }

  @Post('orders/:id/ready') ready(@Req() req: any, @Param('id') id: string) {
    this.needStaff(req);
    return this.prisma.order.update({ where: { id }, data: { status: 'READY' } });
  }

  // Выдано в кружке + скан QR гостя = начисление печатей (6 -> купон на 7-й)
  @Post('orders/:id/serve')
  serve(@Req() req: any, @Param('id') id: string, @Body() b: { guestQr: string }) {
    this.needStaff(req);
    return this.loyalty.stamp(id, b.guestQr);
  }
}