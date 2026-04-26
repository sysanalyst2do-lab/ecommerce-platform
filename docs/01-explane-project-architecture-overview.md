# Полный обзор проекта ecommerce-platform

Этот документ фиксирует текущее устройство проекта: как организованы frontend, backend и база данных, а также какие ключевые процедуры, сущности и методы используются.

## 1. Общая структура репозитория

Проект организован как монорепозиторий с несколькими основными папками:

- `backend` — Python/FastAPI приложение с REST API и доступом к PostgreSQL через SQLAlchemy.
- `frontend` — React + TypeScript (Vite) SPA для работы с заказами.
- `db` — SQL-схема, начальные данные, роли, аналитические представления и DBML-описание.
- `docs` — архитектурные и проектные статьи.
- `openapi.yaml` — контракт API, который отдаётся backend через `/openapi.yaml`.
- `docker-compose.yml` — локальная оркестрация сервисов.

## 2. Как устроен backend

### 2.1 Основные файлы backend

- `backend/app/main.py` — точка входа FastAPI-приложения.
- `backend/app/database.py` — настройка engine/session для PostgreSQL.
- `backend/app/models.py` — ORM-модели SQLAlchemy.
- `backend/app/schemas.py` — Pydantic-схемы запросов/ответов.
- `backend/app/routers/orders.py` — API по заказам.
- `backend/app/routers/cookies.py` — демонстрационные endpoints по cookie.

### 2.2 Архитектурный стиль backend

Текущий backend — компактный REST-монолит:

- роутеры принимают HTTP-запросы;
- валидация выполняется через Pydantic-схемы;
- доступ к данным выполняется через SQLAlchemy-сессию;
- бизнес-логика находится в роутерах (отдельный service/repository слой минимален).

### 2.3 Ключевые backend-процедуры

1. Получение списка заказов (`GET /api/v1/orders`): фильтрация, пагинация, загрузка связанных данных.
2. Получение карточки заказа (`GET /api/v1/orders/{order_id}`): детальные данные заказа.
3. Создание заказа (`POST /api/v1/orders`): создание шапки заказа, позиций и опционально платежа.
4. Смена статуса (`PATCH /api/v1/orders/{order_id}/status`): проверка допустимого перехода статуса.
5. Удаление заказа (`DELETE /api/v1/orders/{order_id}`): удаление с каскадом дочерних сущностей.
6. Проверка здоровья (`GET /health`): состояние приложения, опционально БД и OpenAPI файла.

### 2.4 Основные классы/модели backend и назначение

В `backend/app/models.py`:

- `Customer` — клиент.
- `Order` — заказ (шапка).
- `OrderItem` — позиция заказа.
- `Payment` — платеж по заказу.

### 2.5 Ключевые backend-методы и функции

- `get_db()` (`database.py`) — выдаёт сессию БД на время запроса.
- `_next_order_id()` (`orders.py`) — генерирует идентификатор заказа.
- `list_orders()` — возвращает список заказов.
- `get_order()` — возвращает один заказ.
- `create_order()` — создаёт заказ и связанные сущности.
- `update_status()` — изменяет статус заказа по допустимым переходам.
- `delete_order()` — удаляет заказ.
- `health()` (`main.py`) — health endpoint.

## 3. Как устроен frontend

### 3.1 Основные файлы frontend

- `frontend/src/main.tsx` — точка входа React.
- `frontend/src/App.tsx` — layout и маршрутизация.
- `frontend/src/components/OrderList.tsx` — экран списка заказов.
- `frontend/src/components/OrderDetail.tsx` — экран детализации заказа.
- `frontend/src/components/OrderForm.tsx` — экран создания заказа.
- `frontend/src/components/StatusBadge.tsx` — визуализация статуса.
- `frontend/src/api/orders.ts` — HTTP-клиент по заказам.
- `frontend/src/api/cookies.ts` — HTTP-клиент cookie demo.
- `frontend/src/types/order.ts` — типы данных заказа.
- `frontend/vite.config.ts` — Vite-конфигурация и proxy к backend.

### 3.2 Архитектура frontend

Frontend — SPA на React:

- маршрутизация через `react-router-dom`;
- локальное состояние через `useState`/`useEffect`;
- API-запросы через `fetch` и слой `src/api`;
- в development запросы проксируются на backend через Vite.

### 3.3 Основные пользовательские потоки

1. Список заказов (`/`) с фильтром и удалением.
2. Создание заказа (`/orders/new`) через форму.
3. Просмотр заказа (`/orders/:id`) и смена статуса.

### 3.4 Ключевые компоненты и методы frontend

- `OrderList`:
  - `load()` — загрузка списка.
  - `handleDelete()` — удаление заказа и обновление списка.
- `OrderDetailPage`:
  - `handleStatus()` — смена статуса.
  - `handleDelete()` — удаление заказа с переходом на список.
- `OrderForm`:
  - `handleSubmit()` — отправка нового заказа.
  - `addItem()` / `removeItem()` / `updateItem()` — управление позициями.
- `orders.ts`:
  - `fetchOrders()`, `fetchOrder()`, `createOrder()`, `updateStatus()`, `deleteOrder()`.

## 4. Как устроена база данных

### 4.1 Технологии и артефакты

- СУБД: PostgreSQL.
- Основной SQL: `db/init.sql`.
- Описание структуры: `db/schema.dbml`.
- ORM-подмножество в backend: `backend/app/models.py`.

Отдельного инструмента миграций (например Alembic) в текущем репозитории нет. Схема и сиды задаются SQL-скриптом и применяются при инициализации БД.

### 4.2 Основные сущности БД

В схеме присутствуют домены:

- клиенты: `customers`, `addresses`;
- каталог: `categories`, `products`;
- склад: `warehouses`, `inventory`;
- корзина: `carts`, `cart_items`;
- заказы: `orders`, `order_items`, `payments`, `order_status_history`;
- маркетинг и поддержка: `promotions`, `promotion_products`, `support_tickets`;
- сегментация: `customer_segments`, `customer_segment_members`;
- аналитика (schema `analytics`): представления и materialized view.

Важно: backend-код сейчас активно работает только с подмножеством заказного домена (`customers`, `orders`, `order_items`, `payments`).

### 4.3 Что обеспечивает целостность данных

На уровне `init.sql` используются:

- внешние ключи и каскады удаления;
- `CHECK`-ограничения на статусы/типы/значения;
- `UNIQUE`-ограничения;
- индексы по ключевым полям фильтрации и связей.

## 5. Сквозной сценарий работы системы

1. Пользователь работает в React-интерфейсе (`frontend`).
2. UI вызывает функцию API-клиента (`frontend/src/api/orders.ts`).
3. Запрос попадает в endpoint FastAPI (`backend/app/routers/orders.py`).
4. Endpoint использует SQLAlchemy-сессию (`get_db()`).
5. Данные читаются/изменяются в PostgreSQL.
6. Ответ возвращается в UI и отображается компонентами React.

## 6. Ограничения текущей реализации

- В backend отсутствует полноценный автоматизированный тестовый контур (отдельного `tests` набора не найдено).
- Нет полноценного service/repository разделения в backend, логика сосредоточена в роутерах.
- В репозитории нет отдельного процесса управляемых миграций схемы.
- Часть таблиц из `db/init.sql` пока не задействована напрямую в runtime backend-коде.

## 7. Краткий вывод

Текущая реализация — практичный учебно-прикладной стек:

- **Frontend:** React SPA для операций с заказами;
- **Backend:** FastAPI API с базовой бизнес-логикой заказов;
- **БД:** PostgreSQL со значительно более широкой схемой, чем текущий runtime-покрытие backend;
- **Интеграция:** прозрачный поток от UI до SQL через REST и ORM.

Документ можно использовать как базовую точку для онбординга, аудита архитектуры и планирования дальнейшего развития (тестирование, миграции, выделение сервисного слоя, расширение покрытия доменов).
