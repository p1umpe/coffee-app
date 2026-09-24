import { IsArray, IsEnum, IsOptional, IsString, MinLength, ValidateNested, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
export enum FulfillmentDto { DINE_IN = 'DINE_IN', TAKEAWAY = 'TAKEAWAY' }
class ItemDto {
  @IsString() productId!: string;
  @IsInt() @Min(1) qty!: number;
  @IsOptional() modifiers?: Record<string, unknown>;
}
export class CreateOrderDto {
  @IsString() shopId!: string;
  @IsEnum(FulfillmentDto) fulfillment!: FulfillmentDto;
  @IsArray() @ValidateNested({ each: true }) @Type(() => ItemDto) items!: ItemDto[];
  @IsString() @MinLength(8) idempotencyKey!: string; // UUID с клиента
  @IsOptional() @IsString() couponCode?: string; // оплатить бесплатным купоном
  @IsOptional() @IsString() userId?: string; // cuid; в проде — из JWT
}
