import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { LoyaltyService } from './loyalty.service';
@Controller('loyalty')
export class LoyaltyController {
  constructor(private loyalty: LoyaltyService) {}
  @Get('me/:userId') me(@Param('userId') u: string) { return this.loyalty.me(u); }
  // Вызывает бариста: скан QR + кнопка "Выдано в кружке"
  @Post('stamp') stamp(@Body() b: { orderId: string; guestQr: string }) {
    return this.loyalty.stamp(b.orderId, b.guestQr);
  }
}
