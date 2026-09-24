import { Module } from '@nestjs/common';
import { IikoService } from './iiko.service';
import { IikoController } from './iiko.controller';
@Module({ providers: [IikoService], controllers: [IikoController], exports: [IikoService] })
export class IikoModule {}
