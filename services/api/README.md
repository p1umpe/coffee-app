# Simple Coffee API — как запустить (для новичка)

## 0. Что мы построили
Модульный монолит NestJS: `auth (OTP+JWT)`, `shops`, `catalog (menu?shopId)`,
`orders (DINE_IN/TAKEAWAY + идемпотентность)`, `loyalty (stamp по QR)`, `iiko (mock + webhook)`.
БД: Postgres + Prisma. Документация: http://localhost:3000/docs

## 1. Запуск за 5 команд
```bash
cd /Users/p1umpe/Desktop/coffee-app
docker compose up -d postgres redis          # БД и кэш
cd services/api
cp .env.example .env
npm install
npx prisma migrate dev --name init           # создаст таблицы
npx prisma db seed                            # демо-кофейня + 6 товаров
npm run start:dev                             # API на :3000
```

## 2. Проверка сценария «Кружка = печать»
```bash
# здоровье
curl localhost:3000/v1/health
# кофейни
curl localhost:3000/v1/shops | head -c 500
# возьми shopId из сида (вывелся в консоль) и запроси меню:
SHOP=<shopId>
curl "localhost:3000/v1/menu?shopId=$SHOP"
# OTP (dev-код вернётся в ответе):
curl -X POST localhost:3000/v1/auth/otp/request -H 'Content-Type: application/json' -d '{"phone":"+79000000000"}'
# verify -> получишь accessToken + guestQr:
curl -X POST localhost:3000/v1/auth/otp/verify -H 'Content-Type: application/json' -d '{"phone":"+79000000000","code":"1234"}'
# заказ В КРУЖКЕ (замени PRODUCT_ID):
curl -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -d '{"shopId":"'$SHOP'","fulfillment":"DINE_IN","userId":"<userId>","idempotencyKey":"<uuid>","items":[{"productId":"<PRODUCT_ID>","qty":2}]}'
# бариста ставит печати сканом QR:
curl -X POST localhost:3000/v1/loyalty/stamp -H 'Content-Type: application/json' -d '{"orderId":"<orderId>","guestQr":"<guestQr>"}'
```

## 3. Что дальше
- Подключить боевой iiko: заполнить IIKO_API_KEY в .env и дописать `IikoService.createPickupOrder` (помечено TODO).
- Платежи (СБП/карта): добавить модуль payments + webhook, сейчас заказы PENDING_PAYMENT (кроме купона).
- Админка: стоп-лист endpoint `POST /v1/admin/stop-list` (следующая итерация).
