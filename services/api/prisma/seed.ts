import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

// Сид: 1 кофейня, категории, 6 товаров + тестовый бариста (login barista1 / PIN 1234).
const prisma = new PrismaClient();
async function main() {
  const shop = await prisma.shop.upsert({
    where: { iikoId: 'demo-ekb-01' },
    update: {},
    create: { name: 'Simple Coffee — Ленина', address: 'Екатеринбург, пр. Ленина, 1', lat: 56.838, lon: 60.597, phone: '+7 (343) 000-00-00', iikoId: 'demo-ekb-01', isNew: true },
  });
  const cats: Array<[string, string, number]> = [
    ['novinki', 'Новинки', 0], ['coffee', 'Кофе и напитки', 1],
    ['dessert', 'Десерты', 2], ['bakery', 'Выпечка', 3], ['kitchen', 'Наша кухня', 4],
  ];
  for (const [slug, title, sort] of cats)
    await prisma.category.upsert({ where: { slug }, update: {}, create: { slug, title, sort } });
  const coffee = await prisma.category.findUnique({ where: { slug: 'coffee' } });
  const dessert = await prisma.category.findUnique({ where: { slug: 'dessert' } });
  const kitchen = await prisma.category.findUnique({ where: { slug: 'kitchen' } });

  const items = [
    { title: 'Капучино', desc: 'Классика на фермерском молоке', price: 32000, cat: coffee!.id, stamp: true, tags: ['хит'] },
    { title: 'Раф печёное яблоко', desc: 'Сезонный хит осени', price: 38000, cat: coffee!.id, stamp: true, tags: ['new'] },
    { title: 'Эспрессо-тоник мята-лимон', desc: 'Бодрящий холодный', price: 34000, cat: coffee!.id, stamp: true, tags: ['new'] },
    { title: 'Сырники', desc: 'Со сметаной и ягодой', price: 29000, cat: dessert!.id, stamp: false, tags: [] },
    { title: 'Круассан масляный', desc: 'Выпекаем утром', price: 18000, cat: dessert!.id, stamp: false, tags: [] },
    { title: 'Рап тунец и халуми', desc: 'Сытный, как любят регулярные', price: 39000, cat: kitchen!.id, stamp: false, tags: ['хит'] },
  ];
  for (const it of items) {
    const p = await prisma.product.upsert({
      where: { iikoId: `demo-${it.title}` },
      update: {},
      create: { iikoId: `demo-${it.title}`, title: it.title, description: it.desc, dineInPrice: it.price, categoryId: it.cat, givesStamp: it.stamp, tags: it.tags },
    });
    await prisma.shopProduct.upsert({
      where: { shopId_productId: { shopId: shop.id, productId: p.id } },
      update: {},
      create: { shopId: shop.id, productId: p.id },
    });
  }
  console.log('seed ok, shopId =', shop.id);
  // Сид 2-й кофейни (task_0009): те же 6 товаров, Круассан в стоп-листе, Капучино дороже.
  const shop2 = await prisma.shop.upsert({
    where: { iikoId: 'demo-ekb-02' },
    update: {},
    create: { name: 'Simple Coffee — Вайнера', address: 'Екатеринбург, ул. Вайнера, 9', lat: 56.833, lon: 60.594, phone: '+7 (343) 000-00-01', iikoId: 'demo-ekb-02', isNew: true },
  });
  for (const it of items) {
    const p = await prisma.product.findUnique({ where: { iikoId: `demo-${it.title}` } });
    if (!p) continue;
    const isCroissant = it.title === 'Круассан масляный';
    const isCappuccino = it.title === 'Капучино';
    await prisma.shopProduct.upsert({
      where: { shopId_productId: { shopId: shop2.id, productId: p.id } },
      update: { inStopList: isCroissant, dineInPrice: isCappuccino ? 35000 : null },
      create: { shopId: shop2.id, productId: p.id, inStopList: isCroissant, dineInPrice: isCappuccino ? 35000 : null },
    });
  }
  console.log('seed ok, shop2Id =', shop2.id);
  const pinHash = await bcrypt.hash('1234', 10);
  await prisma.staff.upsert({
    where: { login: 'barista1' },
    update: { pinHash, shopId: shop.id },
    create: { login: 'barista1', pinHash, name: 'Бариста Лена', role: 'BARISTA', shopId: shop.id },
  });
  console.log('staff seeded: barista1 / 1234');
}
main().finally(() => prisma.$disconnect());
