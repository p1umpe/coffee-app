# Simple Coffee API — статус бэкенда (28.09.2026, v0.3, проверено вживую)

## Что работает (API :3000)

- OTP вход (devCode) -> JWT + guestQr ✅
- Menu: напитки 32000/29000 (−30 ₽), еда без скидки (18000/18000), стоп-лист скрыт ✅
- DINE_IN заказ: total 32000, stampsDue 1, статус PENDING_PAYMENT ✅
- Оплата CARD: POST /payments -> PENDING -> POST /payments/:id/confirm -> SUCCEEDED, заказ PAID ✅
- Идемпотентность платежей: повторный ключ возвращает тот же платёж ✅
- КДС (staff JWT barista1/1234): feed, accept -> cooking -> ready ✅
- Выдача в кружке: POST /kds/orders/:id/serve {guestQr} -> stamps=1, повтор отклонён ✅
- Гость без staff-токена получает 401 на /kds ✅

## Тестовые данные (dev)

- shop=cmufoxdhd0000i0sbi70zckpi (Ленина, 1)
- staff: login=barista1 / PIN=1234 (сидируется в prisma/seed.ts)
- Механика: 6 печатей = купон на 7-й кофе (STAMPS_TO_FREE_CUP=6), TTL 30 дней
- Скидка: TAKEAWAY_DISCOUNT=3000, только напитки (givesStamp=true)
- Возврат: POST /v1/payments/:id/refund (идемпотентный; 400 при PENDING/FAILED или COOKING/READY/SERVED) ✅
- shop2=PENDING_DB (Вайнера, 9, iikoId demo-ekb-02; Круассан в стоп-листе, Капучино 35000) — ID подставится после migrate+seed на доступной БД

## Что дальше

- Боевой PSP: заменить confirm на payUrl + webhook с подписью (место помечено TODO).
- Push-уведомления о статусах (FCM/APNs).
- Фронт: экран оплаты (CARD/SBP) + статус заказа + режим бариста по PIN.
