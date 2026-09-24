import { Body, Controller, Param, Post } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { IikoService } from './iiko.service';
@Controller('iiko')
export class IikoController {
  constructor(private prisma: PrismaService, private iiko: IikoService) {}
  // Webhook кухни: { orderNumber, status }
  @Post('webhook') async webhook(@Body() b: { orderNumber: string; status: string }) {
    const mapped = this.iiko.mapStatus(b.status);
    const order = await this.prisma.order.updateMany({
      where: { number: b.orderNumber },
      data: { status: mapped as any },
    });
    return { ok: true, mapped, updated: order.count };
  }
  // Ручной перевод бариста (КДС-кнопка), если iiko молчит
  @Post('orders/:id/status') async setStatus(@Param('id') id: string, @Body() b: { status: string }) {
    const order = await this.prisma.order.update({ where: { id }, data: { status: b.status as any } });
    return order;
  }
}
