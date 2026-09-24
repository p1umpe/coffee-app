import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto';
@Controller('orders')
export class OrdersController {
  constructor(private orders: OrdersService) {}
  @Post() create(@Body() b: CreateOrderDto) { return this.orders.create(b); }
  @Get(':id') get(@Param('id') id: string) { return this.orders.get(id); }
  @Get('by-shop/:shopId') byShop(@Param('shopId') s: string) { return this.orders.byShop(s); }
  @Post(':id/cancel') cancel(@Param('id') id: string) { return this.orders.cancel(id); }
  @Post(':id/served') served(@Param('id') id: string) { return this.orders.markServed(id); }
}
