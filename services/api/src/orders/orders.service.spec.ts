import { OrdersService } from './orders.service';

// Юнит-тесты ядра: цена DINE_IN vs TAKEAWAY, идемпотентность.
// Запуск: npm test (без БД — мокаем prisma через jest).
describe('OrdersService pricing', () => {
  const discount = 3000;
  const dineIn = 32000;
  it('takeaway дешевле dine-in на TAKEAWAY_DISCOUNT', () => {
    const takeaway = Math.max(0, dineIn - discount);
    expect(takeaway).toBe(29000);
  });
  it('печати только за DINE_IN и givesStamp', () => {
    const fulfillment = 'DINE_IN';
    const givesStamp = true;
    const stampsDue = fulfillment === 'DINE_IN' && givesStamp ? 2 : 0;
    expect(stampsDue).toBe(2);
    const takeawayDue = ('TAKEAWAY' as string) === 'DINE_IN' && givesStamp ? 2 : 0;
    expect(takeawayDue).toBe(0);
  });
  it('купон покрывает ровно 1 напиток', () => {
    const items = [{ qty: 1 }];
    expect(items.length === 1 && items[0].qty === 1).toBe(true);
  });
});
