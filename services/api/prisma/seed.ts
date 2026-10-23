import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

// Сид: 2 кофейни, категории, ~20 товаров + тестовый бариста (login barista1 / PIN 1234).
const prisma = new PrismaClient();
async function main() {
  const shop = await prisma.shop.upsert({
    where: { iikoId: 'demo-ekb-01' },
    update: {},
    create: { name: 'Simple Coffee — Ленина', address: 'Екатеринбург, пр. Ленина, 1', lat: 56.838, lon: 60.597, phone: '+7 (343) 000-00-00', iikoId: 'demo-ekb-01', isNew: true },
  });
  const cats: Array<[string, string, number]> = [
    ['novinki', 'Новинки', 0], ['coffee', 'Кофе и напитки', 1],
    ['tea', 'Чай', 2], ['dessert', 'Десерты', 3], ['bakery', 'Выпечка', 4],
    ['kitchen', 'Наша кухня', 5], ['breakfast', 'Завтраки', 6],
  ];
  for (const [slug, title, sort] of cats)
    await prisma.category.upsert({ where: { slug }, update: {}, create: { slug, title, sort } });
  const catOf = async (slug: string) => (await prisma.category.findUnique({ where: { slug } }))!.id;
  const coffee = await catOf('coffee');
  const tea = await catOf('tea');
  const dessert = await catOf('dessert');
  const bakery = await catOf('bakery');
  const kitchen = await catOf('kitchen');
  const breakfast = await catOf('breakfast');
  const novinki = await catOf('novinki');

  const kbjuLatte = { kcal: 120, protein: 6, fat: 5, carbs: 12 };
  const items = [
    // Кофе и напитки (печати, −30 ₽ с собой)
    { title: 'Капучино', desc: 'Классика на фермерском молоке', price: 32000, cat: coffee, stamp: true, tags: ['хит'], kbju: { kcal: 110, protein: 6, fat: 5, carbs: 10 } },
    { title: 'Латте', desc: 'Нежный эспрессо с бархатным молоком', price: 26000, cat: coffee, stamp: true, tags: [], kbju: kbjuLatte },
    { title: 'Флэт уайт', desc: 'Двойной эспрессо, мало молока', price: 24000, cat: coffee, stamp: true, tags: [], kbju: { kcal: 90, protein: 5, fat: 4, carbs: 8 } },
    { title: 'Мокка', desc: 'Шоколад, эспрессо, молоко', price: 29000, cat: coffee, stamp: true, tags: [], kbju: { kcal: 180, protein: 6, fat: 6, carbs: 24 } },
    { title: 'Раф печёное яблоко', desc: 'Сезонный хит осени', price: 38000, cat: coffee, stamp: true, tags: ['new'], kbju: { kcal: 210, protein: 5, fat: 8, carbs: 28 } },
    { title: 'Эспрессо-тоник мята-лимон', desc: 'Бодрящий холодный', price: 34000, cat: coffee, stamp: true, tags: ['new'], kbju: { kcal: 45, protein: 0, fat: 0, carbs: 11 } },
    { title: 'Эспрессо', desc: 'Классический шот 30 мл', price: 18000, cat: coffee, stamp: true, tags: [], kbju: { kcal: 5, protein: 0, fat: 0, carbs: 1 } },
    { title: 'Какао мармеладное', desc: 'С маршмеллоу и корицей', price: 30000, cat: coffee, stamp: true, tags: ['new'], kbju: { kcal: 190, protein: 5, fat: 6, carbs: 30 } },
    // Чай (печати, −30 ₽ с собой)
    { title: 'Чай ягодная конфета', desc: 'Ягоды, гибискус, мёд', price: 28000, cat: tea, stamp: true, tags: ['new'], kbju: { kcal: 60, protein: 0, fat: 0, carbs: 15 } },
    { title: 'Гречишный чай', desc: 'С цедрой и корицей', price: 27000, cat: tea, stamp: true, tags: [], kbju: { kcal: 20, protein: 0, fat: 0, carbs: 5 } },
    { title: 'Матча-латте', desc: 'Японская матча на молоке', price: 33000, cat: tea, stamp: true, tags: [], kbju: { kcal: 130, protein: 6, fat: 5, carbs: 14 } },
    // Десерты (без печатей, цена одна)
    { title: 'Сырники', desc: 'Со сметаной и ягодой', price: 29000, cat: dessert, stamp: false, tags: [], kbju: { kcal: 320, protein: 14, fat: 16, carbs: 28 } },
    { title: 'Торт морковный', desc: 'С крем-чизом и орехами', price: 34000, cat: dessert, stamp: false, tags: ['хит'], kbju: { kcal: 410, protein: 5, fat: 24, carbs: 42 } },
    { title: 'Чизкейк Сан-Себастьян', desc: 'Карамельная корочка', price: 36000, cat: dessert, stamp: false, tags: [], kbju: { kcal: 380, protein: 7, fat: 26, carbs: 30 } },
    // Выпечка (без печатей)
    { title: 'Круассан масляный', desc: 'Выпекаем утром', price: 19000, cat: bakery, stamp: false, tags: [], kbju: { kcal: 290, protein: 5, fat: 17, carbs: 30 } },
    { title: 'Круассан с шоколадом', desc: 'С бельгийским шоколадом', price: 23000, cat: bakery, stamp: false, tags: [], kbju: { kcal: 340, protein: 6, fat: 19, carbs: 38 } },
    { title: 'Булочка с корицей', desc: 'Синнабон-стайл', price: 21000, cat: bakery, stamp: false, tags: [], kbju: { kcal: 310, protein: 5, fat: 14, carbs: 42 } },
    // Кухня (без печатей)
    { title: 'Рап тунец и халуми', desc: 'Сытный, как любят регулярные', price: 39000, cat: kitchen, stamp: false, tags: ['хит'], kbju: { kcal: 450, protein: 24, fat: 22, carbs: 38 } },
    { title: 'Сэндвич с курицей', desc: 'Чиабатта, соус песто', price: 35000, cat: kitchen, stamp: false, tags: [], kbju: { kcal: 420, protein: 26, fat: 18, carbs: 36 } },
    { title: 'Киш с лососем', desc: 'Подаём тёплым', price: 37000, cat: kitchen, stamp: false, tags: [], kbju: { kcal: 390, protein: 16, fat: 26, carbs: 24 } },
    // Завтраки (без печатей)
    { title: 'Каша овсяная', desc: 'На молоке, ягоды и мёд', price: 25000, cat: breakfast, stamp: false, tags: [], kbju: { kcal: 280, protein: 8, fat: 8, carbs: 44 } },
    { title: 'Завтрак с сырниками', desc: 'Сырники + напиток', price: 39000, cat: breakfast, stamp: false, tags: [], kbju: { kcal: 480, protein: 20, fat: 20, carbs: 52 } },
    // Новинки — дубли-ссылки не нужны, новинки собираются тегом
    { title: 'Раф с кокосом', desc: 'Кокосовое молоко, эспрессо', price: 37000, cat: novinki, stamp: true, tags: ['new'], kbju: { kcal: 200, protein: 4, fat: 9, carbs: 26 } },
  ];
  for (const it of items) {
    const p = await prisma.product.upsert({
      where: { iikoId: `demo-${it.title}` },
      update: { description: it.desc, dineInPrice: it.price, categoryId: it.cat, givesStamp: it.stamp, tags: it.tags, kbju: it.kbju ?? undefined },
      create: { iikoId: `demo-${it.title}`, title: it.title, description: it.desc, dineInPrice: it.price, categoryId: it.cat, givesStamp: it.stamp, tags: it.tags, kbju: it.kbju ?? undefined },
    });
    await prisma.shopProduct.upsert({
      where: { shopId_productId: { shopId: shop.id, productId: p.id } },
      update: { inStopList: false },
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
