# ecommerce-platform

Модуль управления заказами e-commerce платформы.

## Архитектура

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Frontend   │─────▶│   Backend    │─────▶│  PostgreSQL   │
│  React + TS  │ REST │  FastAPI     │ SQL  │  16 таблиц   │
│  port 3000   │      │  port 8000   │      │  port 5432   │
└──────────────┘      └──────────────┘      └──────────────┘
                            │
                      ┌─────┴──────┐
                      │  OpenAPI   │
                      │  /docs     │
                      │  /redoc    │
                      └────────────┘
```

## Стек

| Слой | Технология |
|------|-----------|
| Frontend | React 19, TypeScript, Vite, React Router |
| Backend | Python 3.12, FastAPI, SQLAlchemy, Pydantic |
| Database | PostgreSQL 16 |
| OpenAPI | Swagger UI (`/docs`), ReDoc (`/redoc`) |
| Infra | Docker Compose |

## Запуск

### Docker Compose (рекомендуется)

Перед первым запуском создай `.env` на основе примера:

```bash
cp .env.example .env
```

И укажи в `.env` значения:
- `TECH_RO_PASSWORD` — пароль для `ecom_tech_ro` (только чтение)
- `TECH_ADMIN_PASSWORD` — пароль для `ecom_tech_admin` (расширенные права)

```bash
docker-compose up --build
```

После запуска:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000/api/v1/orders
- **OpenAPI (Swagger)**: http://localhost:8000/docs
- **OpenAPI (ReDoc)**: http://localhost:8000/redoc
- **Logs UI (Dozzle)**: http://localhost:8080

### Локальная разработка

**БД:**
```bash
docker-compose up db
```

**Backend:**
```bash
cd backend
pip install -r requirements.txt
DATABASE_URL=postgresql://ecommerce:secret@localhost:5432/ecommerce uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

## Структура проекта

```
ecommerce-platform/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI приложение, CORS, роутеры
│   │   ├── database.py      # Подключение к PostgreSQL
│   │   ├── models.py        # SQLAlchemy модели (Order, OrderItem, Payment, Customer)
│   │   ├── schemas.py       # Pydantic схемы (request/response)
│   │   └── routers/
│   │       └── orders.py    # CRUD эндпоинты заказов
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── api/orders.ts    # HTTP клиент к API
│   │   ├── components/
│   │   │   ├── OrderList.tsx     # Список заказов (List)
│   │   │   ├── OrderDetail.tsx   # Детали заказа (Read) + смена статуса (Update)
│   │   │   ├── OrderForm.tsx     # Создание заказа (Create)
│   │   │   └── StatusBadge.tsx   # Компонент статуса
│   │   └── types/order.ts   # TypeScript типы
│   ├── package.json
│   └── Dockerfile
├── db/
│   └── init.sql             # Полная схема БД (все домены) + seed data
├── docker-compose.yml
└── README.md
```

## API эндпоинты

| Метод | URL | Описание |
|-------|-----|----------|
| `GET` | `/api/v1/orders` | Список заказов (фильтр по status, customer_id, пагинация) |
| `GET` | `/api/v1/orders/{id}` | Детали заказа |
| `POST` | `/api/v1/orders` | Создать заказ |
| `PATCH` | `/api/v1/orders/{id}/status` | Обновить статус |
| `DELETE` | `/api/v1/orders/{id}` | Удалить заказ |

## Логи (быстрый доступ)

Для простого просмотра логов используется **Dozzle**.

- Web UI: `http://localhost:8080`
- Логи по сервисам: `backend`, `frontend`, `db`
- Live-режим: включи `Follow` в интерфейсе

CLI-альтернатива:

```bash
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
```

## База данных

Полная схема БД реализует все домены из [ecommerce-docs](../ecommerce-docs):

| Домен | Таблицы |
|-------|---------|
| ACC (Аккаунты) | `customers`, `addresses` |
| CAT (Каталог) | `categories`, `products` |
| CRT (Корзина) | `carts`, `cart_items` |
| ORD (Заказы) | `orders`, `order_items`, `order_status_history` |
| CHK (Оплата) | `payments` |
| INV (Склад) | `warehouses`, `inventory` |
| MKT (Маркетинг) | `promotions`, `promotion_products` |
| SUP (Поддержка) | `support_tickets` |
| CLI (CRM) | `customer_segments`, `customer_segment_members` |

## Жизненный цикл заказа

```
created ──▶ paid ──▶ processing ──▶ shipped ──▶ delivered
   │                                               │
   └──────────────▶ cancelled ◀────────────────────┘
```
