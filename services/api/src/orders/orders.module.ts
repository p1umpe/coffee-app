import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { IikoModule } from '../iiko/iiko.module';
@Module({ imports: [IikoModule], providers: [OrdersService], controllers: [OrdersController], exports: [OrdersService] })
export class OrdersModule {}
