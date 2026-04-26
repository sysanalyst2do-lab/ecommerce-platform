# CI/CD для одного production-окружения

Документ описывает наглядный вариант CI/CD для текущего проекта, когда доступно только одно окружение (`production`).

## 1. Схема процесса

1. Разработчик делает `push` в удаленный репозиторий.
2. Запускается `CI Pipeline`:
   - backend тесты,
   - frontend тесты,
   - frontend сборка.
3. В Telegram приходит уведомление о старте CI.
4. После прохождения тестов приходит уведомление об успехе (или о падении CI).
5. Если CI успешно завершился в ветке `main`, запускается `CD Production`.
6. Job деплоя ждет ручного подтверждения через GitHub `environment: production`.
7. После approve выполняется деплой на сервер по SSH.
8. Выполняется smoke-проверка `/health`.
9. В Telegram приходит итоговое уведомление: success/failure деплоя.

## 2. Что проверяется в CI

### Backend

Файл тестов: `backend/tests/test_health_and_orders_logic.py`.

Проверки:

- `test_health_basic_returns_ok` — endpoint `/health` в режиме basic отвечает `200` и `{"status":"ok"}`.
- `test_next_order_id_has_expected_format` — формат `order_id` соответствует `ORD-YYYY-XXXX`.
- `test_status_transitions_reference_only_known_statuses` — матрица переходов статусов не содержит невалидных состояний.

### Frontend

Файл тестов: `frontend/src/types/order.test.ts`.

Проверки:

- словарь `STATUS_LABELS` содержит ожидаемые подписи для всех ключевых статусов;
- словарь `STATUS_COLORS` содержит цвет для каждого статуса.

Также в CI выполняется production-сборка фронтенда: `npm run build`.

## 3. Этапы CI (workflow `ci.yml`)

1. `notify_start` — отправка в Telegram сообщения о старте (`push`).
2. `backend_tests`:
   - установка Python и зависимостей,
   - запуск `pytest`.
3. `frontend_tests`:
   - установка Node.js и npm-зависимостей,
   - запуск `npm run test`,
   - запуск `npm run build`.
4. `notify_success` — сообщение в Telegram о прохождении тестов (`push`).
5. `notify_failure` — сообщение в Telegram при падении backend/frontend этапов (`push`).

## 4. Этапы CD (workflow `cd-prod.yml`)

Триггер: успешное завершение `CI Pipeline` для ветки `main`.

1. `deploy_production` ожидает ручной approve через `environment: production`.
2. После approve:
   - SSH-подключение к серверу;
   - переход в `PROD_APP_PATH`;
   - `git pull --ff-only origin main`;
   - `docker compose up -d --build`;
   - `docker compose ps` (наглядная проверка состояния сервисов);
   - smoke-check: `curl http://localhost:8000/health`.
3. Telegram-уведомления:
   - старт деплоя;
   - успех деплоя;
   - ошибка деплоя.

## 5. Секреты, которые используются

### Telegram

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

### SSH и deploy

- `SSH_HOST`
- `SSH_USER`
- `SSH_PORT`
- `SSH_PRIVATE_KEY`
- `PROD_APP_PATH`

## 6. Почему этот вариант удобен для обучения

- Наглядный полный цикл: `push -> тесты -> approve -> production deploy`.
- Видны quality gates (тесты и сборка до деплоя).
- Видны operational gates (ручной approve перед production).
- Уведомления в Telegram делают процесс наблюдаемым в реальном времени.
