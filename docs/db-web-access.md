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
2. Пройди basic auth reverse proxy:
   - login: `dbadmin`
   - password: `hiccup`
3. После этого откроется страница CloudBeaver.
4. Войди под админом CloudBeaver:
   - логин: `CLOUDBEAVER_ADMIN_NAME`
   - пароль: `CLOUDBEAVER_ADMIN_PASSWORD`
   - Важно: `ecom_tech_ro` не является пользователем CloudBeaver UI, это SQL-пользователь БД.
5. Создай подключение PostgreSQL:
   - Host: `db`
   - Port: `5432`
   - Database: `ecommerce`
   - User: `ecom_tech_ro`
   - Password: значение `TECH_RO_PASSWORD`
6. Сохрани подключение как `Ecommerce (read-only)`.

## Почему не пускает с техучеткой

Если ты вводишь `ecom_tech_ro` на экране логина CloudBeaver, вход не пройдет.

`ecom_tech_ro` используется только внутри подключения к PostgreSQL (в шаге 5), а не для входа в сам веб-интерфейс.

## Если сменили пароль в `.env`, а вход не работает

`db/init-users.sh` выполняется только при первом создании `pgdata`.
Если ты поменял `TECH_RO_PASSWORD`/`TECH_ADMIN_PASSWORD` в уже поднятой БД, нужно синхронизировать роли вручную:

```bash
chmod +x db/sync-tech-users.sh
./db/sync-tech-users.sh
```

После этого проверь подключение в CloudBeaver еще раз.

## Смена basic auth перед production

Текущая пара (`dbadmin` / `hiccup`) демонстрационная и должна быть заменена.

1. Сгенерируй bcrypt-хэш пароля:

```bash
caddy hash-password --plaintext "my_strong_password"
```

2. Обнови блок `basic_auth` в `deploy/Caddyfile`:

```caddy
basic_auth {
    my_user <bcrypt_hash>
}
```

3. Перезапусти Caddy:

```bash
docker compose up -d --build caddy
```

## Если /db открывает главную страницу сайта

Это означает, что CloudBeaver не настроен на работу под path-prefix `/db/`.

Проверь:

1. В `docker-compose.yml` для `cloudbeaver` есть:
   - `CLOUDBEAVER_ROOT_URI: /db/`
2. В `deploy/Caddyfile` используется:
   - `redir /db /db/ 308`
   - `handle /db* { reverse_proxy cloudbeaver:8978 }`
3. После правок выполнен перезапуск:

```bash
docker compose up -d --build cloudbeaver caddy
```

## Рекомендации по безопасности

- Не передавай сотрудникам пароль от `ecom_tech_admin`.
- Сильный пароль для `CLOUDBEAVER_ADMIN_PASSWORD` обязателен.
- Для публичного доступа желательно ограничить вход:
  - по IP (allowlist), или
  - через дополнительную basic auth на reverse proxy.
