# Simple Coffee — Архитектура надёжной масштабируемой системы (v0.1)

## 1. Решение в одну картинку

```
[ iOS (Flutter) ] ─┐
                   ├─→ [ CDN + WAF + LB ] → [ API Gateway (auth, limits) ] → [ Backend services ] → [ PostgreSQL (primary+replica) + Redis + S3 ]
[ Android (Flutter)] ─┘                         │                                     ├─→ [ Queue (orders, pushes, fiscal) ]
[ Web Backoffice ] ─────────────────────────────┘                                     └─→ [ Интеграции: POS iiko, Payments, SMS, ОФД, 2GIS, Push ]
                                                                                         [ Observability: Grafana/Prometheus/OTel/Sentry ]
```

**Почему так:**
- Один мобильный стек (Flutter) = быстрее и дешевле для сети из 20 точек, чем 2 натива.
- Backend — **модульный монолит → микросервисы по мере роста**. На старте не плодим 10 сервисов — делаем 1 деплоящийся сервис с чёткими модулями (catalog, shops, orders, loyalty, payments, notifications), каждый со своей схемой. Делим, когда упрёмся в команду/нагрузку.
- Всё состояние заказа — в очередях + outbox, поэтому переживаем пик и обрыв сети.

## 2. Технологический стек (рекомендация)

| Слой | Выбор MVP | Почему | Альтернатива |
|---|---|---|---|
| Mobile | **Flutter (Dart) + Riverpod, Dio, Hive, FCM + Flame (задел под игру v2.0)** | 1 код iOS+Android, простой вход для новичка, игра на том же стеке без Unity | Натив (отклонён: 2 кода, дольше, дороже) |
| Backend | **NestJS (Node/TS)** + OpenAPI | Один язык TS на бэк + админку (Next.js), зрелый iiko SDK, быстрый найм | Go (когда будет 100+ точек) |
| API | REST (OpenAPI) + WebSocket/SSE для статусов заказа | Просто, кэшируется, чинится | gRPC внутри сети позже |
| БД | **PostgreSQL 15** (primary+async replica) + **Redis** (кэш/сессии/rate-limit) | Транзакции заказов, JSONB для модификаторов | — |
| Файлы | S3-совместимое (Yandex Object Storage) + CDN | Фото меню, чеки PDF | — |
| Очереди | **RabbitMQ / Yandex MQ** (MVP) → Kafka при росте | Outbox, ретраи, КДС | — |
| Поиск | Postgres FTS (MVP) → OpenSearch позже | Поиск «раф кокос» | — |
| Infra | **Yandex Cloud / VK Cloud (РФ, 152-ФЗ)** + Managed K8s + Managed PG/Redis, Terraform | Данные в РФ, меньше DevOps | Selectel |
| CI/CD | GitHub Actions + Docker + ArgoCD, миграции goose/prisma без даунтайма | rollback <5 мин | GitLab CI |
| Auth | Phone OTP + JWT (15 мин) + Refresh rotation | Просто для гостей | — |
| Payments | CloudPayments/ЮKassa (СБП, Apple/Google Pay) | Готовые SDK, ОФД из коробки | — |
| Maps | 2GIS SDK | Точные адреса/пробки в РФ | — |
| Observability | Prometheus+Garfana, Loki, OpenTelemetry, Sentry, AppMetrica | SLO, алерты | — |

## 3. Доменные модули и API (контракт MVP)

- `GET /v1/shops?lat&lon` — ближайшие кофейни.
- `GET /v1/shops/{id}/menu` — меню точки (ETag + CDN, инвалидация при стоп-листе).
- `POST /v1/orders {shopId, items[]+modifiers, slot, paymentMethod, idempotencyKey}` → `201 {orderId, number, eta, payUrl}`.
- `GET /v1/orders/{id} + WS /v1/orders/{id}/stream` — статусы.
- `POST /v1/payments/webhook` — подтверждение оплаты (подпись!).
- `GET /v1/loyalty/me, POST /v1/loyalty/accrue|redeem` — идемпотентно.
- `POST /v1/admin/stop-list` — бариста скрывает позицию за секунды.

## 4. Надёжность заказа (самое важное)

1. Клиент генерирует `Idempotency-Key` → повторный тап «Оплатить» не создаёт дубль.
2. `orders` создаётся в статусе `PENDING_PAYMENT` в одной транзакции + outbox-событие.
3. Воркер подтверждает оплату → ставит `PAID` → отправляет в POS (iiko) с ретраями (exp. backoff 3→30с, DLQ после 10 попыток).
4. POS отвечает `ACCEPTED` + ETA → push «Готовится». Если POS молчит >2 мин — авто-уведомление менеджеру + предложение гостю вернуть деньги в 1 тап.
5. КДС в кофейне работает на WebSocket + локальный кэш; при обрыве — заказы копятся в очереди и догоняют.
6. Возвраты — отдельной сагой (refund → fiscal → loyalty rollback), каждый шаг идемпотентен.

## 5. Масштабирование

- **Фаза 1 (MVP, 1-20 кофеен):** 2-3 пода API за LB, PG 2vCPU/8GB + replica, Redis 1GB. CDN отдаёт 90% каталога. Хватает на 300 rps.
- **Фаза 2 (20-50 кофеен, доставка):** выносим `notifications` и `payments-worker` в отдельные сервисы, Kafka, read-replica для аналитики, шардирование заказов по месяцам.
- **Фаза 3 (100+):** шардирование по `shop_id`, регион-кластеры, CQRS для ленты заказов.

Кэширование:
- `menu:shop:{id}` TTL 60с + инвалидация по событию стоп-листа.
- ETag/If-None-Match, сжатие Brotli, картинки 3 размера.

## 6. Безопасность и ПДн (кратко)

- Секреты в Vault, TLS везде, pinning в приложении, WAF + rate-limit (OTP 5/мин/IP+device).
- PAN не храним, только токены PSP. Логи без телефонов (маска +7 *** ***-12-34).
- Бэкапы PG: daily full + WAL, хранение 30 дней, restore- drill раз в месяц. RPO <5 мин.

## 7. Структура репозитория (предложение)

```
/coffee-app
  /apps/mobile (flutter)
  /apps/backoffice (next.js admin)
  /services/api (nestjs: modules/catalog, shops, orders, loyalty, payments, notifications)
  /packages/contracts (openapi.yaml + generated dart/ts)
  /infra/terraform (vpc, k8s, pg, redis, s3, cdn)
  /docs (01-VISION, 02-REQUIREMENTS, 03-ARCHITECTURE, 04-DESIGN)
  /.github/workflows (lint, test, build, deploy)
```

## 8. План запуска по неделям (MVP 10 недель)

1-2: Контракты OpenAPI + дизайн-система + скелет Flutter + CI.
3-4: Каталог+кофейни+корзина, админка меню/стоп-лист.
5-6: Заказы+статусы+КДС-экран, интеграция iiko (mock → реальная).
7-8: Оплата+возвраты+фискализация, лояльность QR.
9: Push, баннеры, «Напишите нам», КБЖУ, полировка.
10: Нагрузочные тесты, pentest-lite, бета на 2 кофейнях, релиз в TestFlight/Closed Play.

Оценка команды MVP: 1 PM/аналитик, 1 дизайнер, 2 Flutter, 2 backend, 1 QA, 0.5 DevOps.
