import { Controller, Get, Query } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
@Controller('shops')
export class ShopsController {
  constructor(private prisma: PrismaService) {}
  // GET /v1/shops?lat&lon — ближайшие (упрощённо: все, сортировка по расстоянию если даны координаты)
  @Get() async list(@Query('lat') lat?: string, @Query('lon') lon?: string) {
    const shops = await this.prisma.shop.findMany({ orderBy: { name: 'asc' } });
    const la = Number(lat), lo = Number(lon);
    if (Number.isFinite(la) && Number.isFinite(lo)) {
      const dist = (a: number, b: number, c: number, d: number) =>
        Math.hypot(a - c, b - d);
      return shops
        .map((s) => ({ ...s, _d: s.lat != null && s.lon != null ? dist(la, lo, s.lat, s.lon) : 999 }))
        .sort((x, y) => x._d - y._d)
        .map(({ _d, ...r }) => r);
    }
    return shops;
  }
}
