# Simple Coffee — полная инструкция по запуску демо

Коротко: можно запустить **только API** (для проверки эндпоинтов в браузере) или **API + Flutter-приложение** (полное демо в Chrome).

Выберите удобный способ:

- **Способ A — Docker Desktop** (проще всего, особенно на Windows): одна команда поднимет базу, API и приложение.
- **Способ B — без Docker** (ручная установка Postgres, Redis, Node.js, Flutter): если Docker нельзя установить.

---

## 0. Предварительные требования

### Общее для всех способов
- [Git](https://git-scm.com/)
- [Node.js 20+](https://nodejs.org/) (для API)
- [Flutter SDK 3.2+](https://docs.flutter.dev/get-started/install) (только для полного демо с приложением)
- [Google Chrome](https://www.google.com/chrome/)

### Способ A: Docker Desktop
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows / macOS / Linux)

### Способ B: без Docker
- **Windows:** PostgreSQL 15+, Redis 7+ (можно через [Chocolatey](https://chocolatey.org/) или [WSL2](https://learn.microsoft.com/ru-ru/windows/wsl/install))
- **macOS:** `brew install postgresql@15 redis`
- **Linux:** `sudo apt install postgresql redis-server`

---

## 1. Склонировать репозиторий

Откройте терминал (Windows: PowerShell или CMD) и выполните:

```bash
git clone https://github.com/p1umpe/coffee-app.git
cd coffee-app
```

---

## Способ A — запуск через Docker Desktop (рекомендуется)

### 1. Запуск баз данных

```bash
docker compose up -d postgres redis
```

Подождите, пока контейнеры стартуют (обычно 5–10 секунд).

### 2. Запуск API

```bash
cd services/api
npm install
cp .env.example .env 2>/dev/null || true
# Если .env нет, создайте вручную (см. раздел 2.1 ниже)
npx prisma migrate deploy
npx prisma seed
npm run start:dev
```

API будет доступен по адресу: **http://localhost:3000/v1**
Swagger-документация: **http://localhost:3000/docs**

### 3. Запуск Flutter-приложения (в Chrome)

В новом терминале:

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=API_BASE=http://localhost:3000/v1
```

Приложение откроется в браузере по адресу: **http://localhost:5173**

---

## Способ B — запуск без Docker (ручная установка)

### 2.1. Подготовка .env для API

```bash
cd services/api
cat > .env <<'EOF'
DATABASE_URL="postgresql://simple:simple@localhost:5432/simple_coffee?schema=public"
REDIS_URL="redis://localhost:6379"
JWT_SECRET="dev-secret-change-me"
JWT_EXPIRES="15m"
PORT=3000
TAKEAWAY_DISCOUNT=3000
STAMPS_TO_FREE_CUP=6
FREE_CUP_TTL_DAYS=30
EOF
```

> На Windows в PowerShell heredoc `<<'EOF'` может не работать. Создайте файл `.env` вручную через Блокнот со следующим содержимым:
> ```
> DATABASE_URL="postgresql://simple:simple@localhost:5432/simple_coffee?schema=public"
> REDIS_URL="redis://localhost:6379"
> JWT_SECRET="dev-secret-change-me"
> JWT_EXPIRES="15m"
> PORT=3000
> TAKEAWAY_DISCOUNT=3000
> STAMPS_TO_FREE_CUP=6
> FREE_CUP_TTL_DAYS=30
> ```

### 2.2. База данных (PostgreSQL)

Создайте пользователя и базу:

```bash
# macOS / Linux
psql -U postgres -c "CREATE USER simple WITH PASSWORD 'simple';"
psql -U postgres -c "CREATE DATABASE simple_coffee OWNER simple;"

# Windows (если psql в PATH, иначе через pgAdmin / psql от имени postgres)
psql -U postgres -c "CREATE USER simple WITH PASSWORD 'simple';"
psql -U postgres -c "CREATE DATABASE simple_coffee OWNER simple;"
```

### 2.3. Redis

Запустите Redis локально на порту 6379 (по умолчанию после установки).

### 2.4. Запуск API

```bash
cd services/api
npm install
npx prisma migrate deploy
npx prisma seed
npm run start:dev
```

API: **http://localhost:3000/v1**
Swagger: **http://localhost:3000/docs**

### 2.5. Запуск Flutter-приложения

В новом терминале:

```bash
cd apps/mobile
flutter pub get
flutter run -d chrome --web-port 5173 --dart-define=API_BASE=http://localhost:3000/v1
```

Приложение: **http://localhost:5173**

---

## 3. Тестовые аккаунты

| Роль | Телефон / Логин | PIN / Код |
|------|-----------------|-----------|
| Гость (OTP) | `+79161234567` | `1234` |
| Бариста (КДС) | `barista1` | `1234` |

---

## 4. Сценарий демо («смотрите, что может»)

1. **Гость** логинится по телефону + OTP (`+79161234567`, код `1234`).
2. Выбирает кофейню «Simple Coffee — Ленина».
3. Фильтрует меню: чипы «Кофе», «Выпечка», «Завтраки».
4. Добавляет «Латте» и «Круассан» в корзину.
5. Оформляет заказ «С собой», оплачивает картой (демо-оплата).
6. Видит статус заказа и номер `А-XX`.
7. **Бариста** заходит под `barista1` / `1234`.
8. В КДС принимает заказ → готовит → отдаёт.
9. Гость ставит оценку 5 и пишет фидбек.

---

## 5. Только проверить API (без приложения)

Достаточно шагов 0–3 (запустить API). Откройте в браузере:

**http://localhost:3000/docs**

Swagger UI позволит протестировать все эндпоинты прямо в браузере без Flutter.

---

## 6. Решение проблем

| Проблема | Решение |
|----------|---------|
| `prisma migrate` падает | Проверьте, что Postgres запущен, база `simple_coffee` создана, пароль в `.env` совпадает |
| API не стартует на 3000 | Порт занят — смените `PORT` в `.env` |
| Flutter не видит Chrome | Убедитесь, что Chrome установлен; `flutter doctor` не должен показывать критичных ошибок |
| Приложение не соединяется с API | Проверьте `--dart-define=API_BASE=http://localhost:3000/v1` при запуске Flutter |
| Windows: `psql` не найден | Добавьте папку `bin` PostgreSQL в переменную PATH, или используйте pgAdmin |
| Windows: команды не работают | Используйте PowerShell или Git Bash вместо CMD |
