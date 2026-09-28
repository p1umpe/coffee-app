import { Module } from '@nestjs/common';
import { KdsController } from './kds.controller';
import { LoyaltyModule } from '../loyalty/loyalty.module';
import { AuthModule } from '../auth/auth.module';

// КДС в том же приложении: AuthModule даёт JwtGuard,
// LoyaltyModule (с exports) даёт LoyaltyService, PrismaService — глобальный.
@Module({ imports: [AuthModule, LoyaltyModule], controllers: [KdsController] })
export class KdsModule {}