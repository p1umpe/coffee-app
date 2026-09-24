import { Controller, Get, Query, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

// GET /v1/menu?shopId=... — цены DINE_IN (база) и TAKEAWAY (дешевле), стоп-лист скрываем.
@Controller('menu')
export class CatalogController {
  constructor(private prisma: PrismaService, private config: ConfigService) {}
  @Get() async menu(@Query('shopId') shopId?: string) {
    if (!shopId) throw new BadRequestException('shopId required');
    const discount = Number(this.config.get('TAKEAWAY_DISCOUNT') ?? 3000);
    const links = await this.prisma.shopProduct.findMany({
      where: { shopId, inStopList: false, product: { isActive: true } },
      include: { product: { include: { category: true } } },
      orderBy: { product: { title: 'asc' } },
    });
    return links.map((l) => {
      const dineIn = l.dineInPrice ?? l.product.dineInPrice;
      const takeaway = l.takeawayPrice ?? Math.max(0, dineIn - discount);
      return {
        id: l.product.id,
        title: l.product.title,
        description: l.product.description,
        imageUrl: l.product.imageUrl,
        category: l.product.category ? { slug: l.product.category.slug, title: l.product.category.title } : null,
        givesStamp: l.product.givesStamp,
        tags: l.product.tags,
        kbju: l.product.kbju,
        dineInPrice: dineIn,
        takeawayPrice: takeaway,
      };
    });
  }
}
