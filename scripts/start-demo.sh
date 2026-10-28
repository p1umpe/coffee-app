#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/p1umpe/Desktop/coffee-app"
API_DIR="$ROOT/services/api"
MOBILE_DIR="$ROOT/apps/mobile"
FLUTTER="$HOME/development/flutter/bin/flutter"
WEB_PORT=5173
API_BASE="http://localhost:3000/v1"

echo "🚀 Simple Coffee — запуск демо"
echo ""

# 1. БД
echo "📦 Запуск Postgres (5433) + Redis (6380)..."
docker compose -f "$ROOT/docker-compose.yml" up -d postgres redis

echo "⏳ Ожидание Postgres..."
for i in $(seq 1 30); do
  if docker compose -f "$ROOT/docker-compose.yml" exec -T postgres pg_isready -U simple >/dev/null 2>&1; then
    echo "   Postgres готов"
    break
  fi
  sleep 1
done

# 2. API
cd "$API_DIR"
echo "🗄️ Миграции и сид базы..."
export DATABASE_URL="postgresql://simple:simple@localhost:5433/simple_coffee?schema=public"
npx prisma migrate deploy
npx prisma seed

echo "🖥️ Запуск API на http://localhost:3000..."
npm run start:dev > /tmp/sc-api.log 2>&1 &
API_PID=$!

# 3. Flutter Web
cd "$MOBILE_DIR"
echo "📱 Запуск Flutter Web на http://localhost:$WEB_PORT ..."
"$FLUTTER" run -d chrome --web-port "$WEB_PORT" --dart-define=API_BASE="$API_BASE" > /tmp/sc-flutter.log 2>&1 &
FLUTTER_PID=$!

sleep 3
open -a "Google Chrome" "http://localhost:$WEB_PORT" 2>/dev/null || true

echo ""
echo "✅ Готово!"
echo "   Приложение: http://localhost:$WEB_PORT"
echo "   API:        http://localhost:3000/v1"
echo "   Логи API:   /tmp/sc-api.log"
echo "   Логи Flutter: /tmp/sc-flutter.log"
echo ""
echo "Нажмите Ctrl+C для остановки всего."
wait
