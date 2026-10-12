import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';

// Напишите нам (task_0013): тикеты Похвалить/Пожаловаться/Аренда/Сотрудничество.
// FLOW H. Фото чека — позже (нужен S3), пока текст + контакт.
class FeedbackDto {
  @IsIn(['PRAISE', 'COMPLAINT', 'RENT', 'PARTNERSHIP']) topic!: 'PRAISE' | 'COMPLAINT' | 'RENT' | 'PARTNERSHIP';
  @IsString() @MinLength(3) @MaxLength(2000) text!: string;
  @IsOptional() @IsString() @MaxLength(100) userId?: string;
  @IsOptional() @IsString() @MaxLength(100) contact?: string;
}

@Controller('feedback')
export class FeedbackController {
  constructor(private prisma: PrismaService) {}

  @Post() create(@Body() b: FeedbackDto) {
    return this.prisma.feedback.create({
      data: { topic: b.topic as any, text: b.text, userId: b.userId ?? null, contact: b.contact ?? null },
    });
  }

  @Get() list(@Query('take') take?: string) {
    const t = Math.min(Math.max(Number(take) || 20, 1), 50);
    return this.prisma.feedback.findMany({ orderBy: { createdAt: 'desc' }, take: t });
  }
}
