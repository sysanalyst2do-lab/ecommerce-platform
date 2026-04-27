# SMTP demo через MailHog

Документ описывает учебную демонстрацию SMTP без отправки реальных писем.

## Что добавлено

- Новый сервис `mailhog` в `docker-compose.yml`:
  - SMTP: `1025`
  - Web UI: `8025`
- Новый endpoint backend:
  - `POST /api/v1/mail/test`
- Переменные окружения backend:
  - `SMTP_HOST` (по умолчанию `mailhog`)
  - `SMTP_PORT` (по умолчанию `1025`)
  - `SMTP_FROM` (по умолчанию `no-reply@ecommerce.local`)
  - `SMTP_TIMEOUT_SEC` (по умолчанию `5`)

## Запуск

```bash
docker compose up --build -d db backend frontend cloudbeaver dozzle mailhog
```

Проверка:

- API: `http://localhost:8000/docs`
- MailHog UI: `http://localhost:8025`

## Команда для отправки тестового письма

```bash
curl -X POST http://localhost:8000/api/v1/mail/test \
  -H "Content-Type: application/json" \
  -d '{"to":"student@example.com","subject":"SMTP demo","body":"Hello from SMTP demo"}'
```

Ожидаемый ответ:

```json
{
  "message": "mail queued",
  "smtp_host": "mailhog",
  "smtp_port": 1025
}
```

После этого письмо появится в MailHog UI.

## Сценарий показа на занятии

1. Открыть `http://localhost:8025` (пока пусто).
2. Выполнить `POST /api/v1/mail/test`.
3. Обновить MailHog UI и показать полученное письмо.
4. Пояснить, что SMTP-доставка в учебном контуре завершается на локальном SMTP-сервере, без выхода в интернет.
