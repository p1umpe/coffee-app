# Simple Coffee API — статус бэкенда (24.09.2026, проверено вживую)

Запущено и протестировано curl: Postgres+Redis в Docker, API :3000, Swagger /docs.

Проверенные сценарии:
- OTP вход (devCode) -> JWT + guestQr ✅
- Menu: dineInPrice/takeawayPrice (32000/29000), стоп-лист скрыт ✅
- DINE_IN заказ 2 капучино: total 64000, stampsDue 2 ✅
- stamp по QR: stamps=2, повтор отклонён ✅
- TAKEAWAY: total 29000 (скидка 3000), stamp отклонён ✅
- Идемпотентность: deduped=true ✅

Тестовые ID (dev): shop=cmufoxdhd0000i0sbi70zckpi, user=cmufoxvoa0001jpllh13og8ic
