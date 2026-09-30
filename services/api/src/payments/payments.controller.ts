import { Body, Controller, Post, Param } from '@nestjs/common';
import { IsString, IsOptional, IsIn, MinLength } from 'class-validator';
import { PaymentsService } from './payments.service';

class CreatePaymentDto {
  @IsString() orderId!: string;
  @IsIn(['CARD', 'SBP', 'COUPON', 'CASH_DESK']) method!: 'CARD' | 'SBP' | 'COUPON' | 'CASH_DESK';
  @IsString() @MinLength(8) idempotencyKey!: string;
  @IsOptional() @IsString() couponCode?: string;
}

@Controller('payments')
export class PaymentsController {
  constructor(private payments: PaymentsService) {}

  // Создать платёж: CARD/SBP (мок, затем confirm) | COUPON (гасит total) | CASH_DESK (оплата в кофейне)
  @Post() create(@Body() b: CreatePaymentDto) {
    return this.payments.create(b.orderId, b.method, b.idempotencyKey, b.couponCode);
  }

  // Мок-подтверждение эквайринга. В проде сюда придёт webhook провайдера.
  @Post(':id/confirm') confirm(@Param('id') id: string, @Body() b?: { ok?: boolean }) {
    return this.payments.confirm(id, b?.ok ?? true);
  }

  // Возврат: идемпотентный; 400 если PENDING/FAILED или заказ уже COOKING/READY/SERVED
  @Post(':id/refund') refund(@Param('id') id: string) {
    return this.payments.refund(id);
  }

  @Post('webhook') webhook(@Body() b: { providerPayId: string; status: string; paymentId?: string }) {
    return this.payments.webhook(b);
  }
}