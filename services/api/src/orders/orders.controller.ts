import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto';
@Controller('orders')
export class OrdersController {
  constructor(private orders: OrdersService) {}
  @Post() create(@Body() b: CreateOrderDto) { return this.orders.create(b); }
  @Get('my') my(@Query('userId') userId: string, @Query('take') take?: string, @Query('skip') skip?: string) { return this.orders.myOrders(userId, take ? Number(take) : 20, skip ? Number(skip) : 0); }
  @Get('by-shop/:shopId') byShop(@Param('shopId') s: string) { return this.orders.byShop(s); }
  @Get(':id') get(@Param('id') id: string) { return this.orders.get(id); }
  @Post(':id/cancel') cancel(@Param('id') id: string) { return this.orders.cancel(id); }
  @Post(':id/served') served(@Param('id') id: string) { return this.orders.markServed(id); }
}
