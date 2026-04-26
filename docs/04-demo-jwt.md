# JWT Demo: учебный сценарий для занятия

Документ для быстрой и наглядной демонстрации JWT в текущем проекте без изменения существующих методов заказов.

## 1. Что уже реализовано в проекте

В backend добавлен изолированный demo-модуль:

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`

Текущий модуль предназначен для обучения:

- access token (короткий срок жизни),
- refresh token (длиннее),
- проверка подписи и срока жизни,
- отзыв refresh token при logout.

## 2. Учебные пользователи

- `student` / `student123`
- `teacher` / `teacher123`

## 3. Сценарий демонстрации (10-15 минут)

### Шаг 1. Логин и получение токенов

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"student","password":"student123"}'
```

Ожидаем:

- `access_token`
- `refresh_token`
- `expires_in`
- `refresh_expires_in`

### Шаг 2. Вызов защищенного метода с access token

```bash
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

Ожидаем `200` и payload с:

- `sub`
- `role`
- `exp`

### Шаг 3. Показать, что без токена доступ запрещен

```bash
curl http://localhost:8000/api/v1/auth/me
```

Ожидаем `401` (missing bearer token).

### Шаг 4. Обновить access через refresh

```bash
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<REFRESH_TOKEN>"}'
```

Ожидаем новый `access_token` и новый `refresh_token`.

### Шаг 5. Logout и проверка отзыва refresh token

```bash
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<NEW_REFRESH_TOKEN>"}'
```

Проверка после logout:

```bash
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<NEW_REFRESH_TOKEN>"}'
```

Ожидаем `401` (invalid refresh token).

## 4. Что объяснить студентам по ходу

1. JWT состоит из header, payload, signature.
2. Сервер не хранит access token (stateless-проверка подписи и exp).
3. Refresh token используется для получения нового access token.
4. Logout в таком подходе обычно инвалидирует refresh token.
5. Почему это demo:
   - in-memory хранилище refresh (в production нужен Redis/БД),
   - учебные креды в коде,
   - простой secret из env.

## 5. Частые вопросы на занятии

### Почему не защищены остальные endpoints?

Сделано специально: модуль изолирован для наглядной демонстрации JWT без изменения существующей логики заказов.

### Где смотреть токен?

Можно декодировать токен на [jwt.io](https://jwt.io/) и показать студентам claims (`sub`, `role`, `exp`).

### Чем отличается JWT от сессий?

- JWT: stateless, подпись в токене.
- Session: stateful, сессия хранится на сервере, клиент хранит только session id (cookie).

## 6. Мини-чеклист для преподавателя

- backend запущен на `http://localhost:8000`
- `/docs` открывается
- команды из раздела 3 выполняются последовательно
- студенты видят `200` и `401` в нужных местах
- показан цикл login -> me -> refresh -> logout
