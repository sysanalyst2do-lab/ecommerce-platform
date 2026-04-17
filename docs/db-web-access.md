# Web доступ к БД (read-only)

Этот проект поддерживает web-доступ к PostgreSQL через CloudBeaver.

## Что это дает

- Сотрудники открывают БД в браузере.
- Для SQL используется только техническая учетная запись `ecom_tech_ro` (read-only).
- Установка и запуск выполняются одним контейнером.

## URL

- `https://demo2dev.ru/db`

## Подготовка

1. Убедись, что в `.env` заданы:
   - `TECH_RO_PASSWORD`
   - `CLOUDBEAVER_ADMIN_NAME`
   - `CLOUDBEAVER_ADMIN_PASSWORD`
2. Подними контейнеры:

```bash
docker compose up -d --build cloudbeaver caddy
```

## Первый вход в CloudBeaver

1. Открой `https://demo2dev.ru/db`.
2. Войди под админом CloudBeaver:
   - логин: `CLOUDBEAVER_ADMIN_NAME`
   - пароль: `CLOUDBEAVER_ADMIN_PASSWORD`
3. Создай подключение PostgreSQL:
   - Host: `db`
   - Port: `5432`
   - Database: `ecommerce`
   - User: `ecom_tech_ro`
   - Password: значение `TECH_RO_PASSWORD`
4. Сохрани подключение как `Ecommerce (read-only)`.

## Рекомендации по безопасности

- Не передавай сотрудникам пароль от `ecom_tech_admin`.
- Сильный пароль для `CLOUDBEAVER_ADMIN_PASSWORD` обязателен.
- Для публичного доступа желательно ограничить вход:
  - по IP (allowlist), или
  - через дополнительную basic auth на reverse proxy.
