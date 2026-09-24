# Simple Coffee ☕🦊

Мобильное приложение сети кофеен Simple Coffee (Екатеринбург):
заказ без очереди + лояльность «в кружке = печать, с собой = дешевле».

## Структура

- `docs/` — видение, требования, архитектура, дизайн, ADR-решения
- `services/api/` — бэкенд NestJS (auth, shops, catalog, orders, loyalty, iiko) + Prisma/Postgres
- `apps/mobile/` — фронт Flutter (меню, кофейни, заказ, печати + задел под игру Flame)
- `packages/contracts/openapi.yaml` — контракт API
- `docker-compose.yml` — Postgres :5433 + Redis :6380
- `infra/terraform/` — (TODO: Yandex Cloud, Managed K8s/PG)
- `apps/backoffice/` — (TODO: админка стоп-листов и КДС)

## Быстрый старт (бэк)

```bash
docker compose up -d postgres redis
cd services/api
cp .env.example .env
npm install
npx prisma migrate dev
./node_modules/.bin/ts-node prisma/seed.ts
npm run start:dev   # :3000, Swagger /docs
```

Подробнее: `services/api/README.md`, `apps/mobile/README.md`, `docs/`.
