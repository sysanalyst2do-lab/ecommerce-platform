-- ============================================================
-- E-commerce Platform — Full Database Schema
-- Domains: CAT, CRT, CHK, ORD, ACC, INV, MKT, SUP, CLI
-- ============================================================


-- ======================== ACC ========================

CREATE TABLE customers (
    id            SERIAL        PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(255)  NOT NULL UNIQUE,
    phone         VARCHAR(20),
    password_hash VARCHAR(255),
    is_verified   BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE TABLE addresses (
    id           SERIAL        PRIMARY KEY,
    customer_id  INTEGER       NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    label        VARCHAR(50),
    city         VARCHAR(100)  NOT NULL,
    street       VARCHAR(255)  NOT NULL,
    building     VARCHAR(20)   NOT NULL,
    apartment    VARCHAR(20),
    postal_code  VARCHAR(10)   NOT NULL,
    country_code CHAR(2)       NOT NULL DEFAULT 'RU',
    is_default   BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_addresses_customer ON addresses(customer_id);


-- ======================== CAT ========================

CREATE TABLE categories (
    id        SERIAL       PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    parent_id INTEGER      REFERENCES categories(id),
    sort_order INTEGER     NOT NULL DEFAULT 0,
    is_active BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE products (
    id          SERIAL        PRIMARY KEY,
    sku         VARCHAR(20)   NOT NULL UNIQUE,
    name        VARCHAR(255)  NOT NULL,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    category_id INTEGER       REFERENCES categories(id),
    brand       VARCHAR(100),
    image_url   VARCHAR(500),
    is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku      ON products(sku);


-- ======================== INV ========================

CREATE TABLE warehouses (
    id       SERIAL       PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    location VARCHAR(255)
);

CREATE TABLE inventory (
    id           SERIAL   PRIMARY KEY,
    product_id   INTEGER  NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    warehouse_id INTEGER  NOT NULL REFERENCES warehouses(id),
    quantity     INTEGER  NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    min_level    INTEGER  NOT NULL DEFAULT 5,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(product_id, warehouse_id)
);


-- ======================== CRT ========================

CREATE TABLE carts (
    id          SERIAL      PRIMARY KEY,
    customer_id INTEGER     REFERENCES customers(id),
    session_id  VARCHAR(100),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cart_items (
    id         SERIAL  PRIMARY KEY,
    cart_id    INTEGER NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    UNIQUE(cart_id, product_id)
);


-- ======================== ORD / CHK ========================

CREATE TABLE orders (
    order_id    VARCHAR(20)  PRIMARY KEY,
    customer_id INTEGER      NOT NULL REFERENCES customers(id),
    status      VARCHAR(20)  NOT NULL DEFAULT 'created'
                CHECK (status IN ('created','paid','processing','shipped','delivered','cancelled')),
    is_paid     BOOLEAN      NOT NULL DEFAULT FALSE,
    comment     TEXT,

    -- meta
    source      VARCHAR(20),
    ip          VARCHAR(45),
    tags        TEXT[],

    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status   ON orders(status);
CREATE INDEX idx_orders_created  ON orders(created_at);

CREATE TABLE order_items (
    id         SERIAL        PRIMARY KEY,
    order_id   VARCHAR(20)   NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id VARCHAR(20)   NOT NULL,
    name       VARCHAR(255)  NOT NULL,
    quantity   INTEGER       NOT NULL CHECK (quantity > 0),
    price      NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    in_stock   BOOLEAN       NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE TABLE payments (
    id       SERIAL        PRIMARY KEY,
    order_id VARCHAR(20)   NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    method   VARCHAR(20)   NOT NULL CHECK (method IN ('card','cash','sbp','wallet')),
    total    NUMERIC(10,2) NOT NULL CHECK (total > 0),
    currency CHAR(3)       NOT NULL DEFAULT 'RUB',
    paid_at  TIMESTAMPTZ
);

CREATE INDEX idx_payments_order ON payments(order_id);

CREATE TABLE order_status_history (
    id         SERIAL       PRIMARY KEY,
    order_id   VARCHAR(20)  NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    status     VARCHAR(20)  NOT NULL,
    changed_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    changed_by VARCHAR(100) NOT NULL DEFAULT 'system',
    comment    TEXT
);

CREATE INDEX idx_order_history_order ON order_status_history(order_id);


-- ======================== MKT ========================

CREATE TABLE promotions (
    id             SERIAL       PRIMARY KEY,
    code           VARCHAR(50)  NOT NULL UNIQUE,
    type           VARCHAR(20)  NOT NULL CHECK (type IN ('percentage','fixed','free_shipping')),
    description    VARCHAR(255),
    discount_value NUMERIC(10,2) NOT NULL,
    min_order_sum  NUMERIC(10,2),
    start_date     TIMESTAMPTZ  NOT NULL,
    end_date       TIMESTAMPTZ  NOT NULL,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE promotion_products (
    promotion_id INTEGER NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    product_id   INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    PRIMARY KEY (promotion_id, product_id)
);


-- ======================== SUP ========================

CREATE TABLE support_tickets (
    id          SERIAL       PRIMARY KEY,
    customer_id INTEGER      REFERENCES customers(id),
    subject     VARCHAR(255) NOT NULL,
    message     TEXT         NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'open'
                CHECK (status IN ('open','in_progress','resolved','closed')),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tickets_customer ON support_tickets(customer_id);


-- ======================== CLI ========================

CREATE TABLE customer_segments (
    id          SERIAL       PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE customer_segment_members (
    segment_id  INTEGER NOT NULL REFERENCES customer_segments(id) ON DELETE CASCADE,
    customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    PRIMARY KEY (segment_id, customer_id)
);


-- ============================================================
-- Seed Data
-- ============================================================

INSERT INTO customers (id, name, email, phone, is_verified) VALUES
    (1, 'Алексей Петров',  'a.petrov@example.com',  '+79161234567', TRUE),
    (2, 'Мария Иванова',   'm.ivanova@example.com', '+79269876543', TRUE),
    (3, 'Дмитрий Сидоров', 'd.sidorov@example.com', NULL,           FALSE);
SELECT setval('customers_id_seq', 3);

INSERT INTO categories (id, name, parent_id, sort_order) VALUES
    (1, 'Электроника',  NULL, 1),
    (2, 'Наушники',     1,    1),
    (3, 'Аксессуары',   1,    2),
    (4, 'Кабели',       3,    1),
    (5, 'Одежда',       NULL, 2);
SELECT setval('categories_id_seq', 5);

INSERT INTO products (id, sku, name, description, price, category_id, brand, is_active) VALUES
    (1, 'SKU-1001', 'Наушники Sony WH-1000XM5', 'Беспроводные наушники с шумоподавлением', 32990.00, 2, 'Sony',    TRUE),
    (2, 'SKU-1002', 'Наушники Sony WH-1000XM4', 'Предыдущее поколение',                    24990.00, 2, 'Sony',    TRUE),
    (3, 'SKU-2045', 'Чехол для наушников',       'Кожаный чехол',                           1500.00,  3, NULL,      TRUE),
    (4, 'SKU-3378', 'Кабель USB-C 2м',           'USB-C to USB-C',                          690.00,   4, 'Baseus',  TRUE),
    (5, 'SKU-5010', 'Футболка белая L',           'Хлопок 100%',                            1200.00,  5, 'Basic',   TRUE);
SELECT setval('products_id_seq', 5);

INSERT INTO warehouses (id, name, location) VALUES
    (1, 'Основной склад', 'Москва, ул. Складская 1');

INSERT INTO inventory (product_id, warehouse_id, quantity, min_level) VALUES
    (1, 1, 50,  10),
    (2, 1, 30,  10),
    (3, 1, 200, 20),
    (4, 1, 500, 50),
    (5, 1, 0,   25);

INSERT INTO addresses (customer_id, label, city, street, building, apartment, postal_code, is_default) VALUES
    (1, 'Дом',    'Москва', 'ул. Ленина',    '42', '7А',  '101000', TRUE),
    (1, 'Работа', 'Москва', 'ул. Тверская',  '10', '501', '125009', FALSE),
    (2, 'Дом',    'Санкт-Петербург', 'Невский пр.', '100', '12', '190000', TRUE);

INSERT INTO orders (order_id, customer_id, status, is_paid, comment, source, ip, tags, created_at) VALUES
    ('ORD-2026-0042', 1, 'shipped',   TRUE,  NULL,                      'web',    '192.168.1.100', ARRAY['электроника','промо'],              '2026-03-05T14:32:07+03:00'),
    ('ORD-2026-0043', 2, 'created',   FALSE, 'Позвонить для уточнения', 'mobile', '10.0.0.55',     ARRAY['одежда'],                           '2026-03-05T15:10:00+03:00'),
    ('ORD-2026-0044', 1, 'delivered', TRUE,  NULL,                      'web',    '192.168.1.100', ARRAY['электроника','повторный_клиент'],    '2026-03-01T09:00:00+03:00');

INSERT INTO order_items (order_id, product_id, name, quantity, price, in_stock) VALUES
    ('ORD-2026-0042', 'SKU-1001', 'Наушники Sony WH-1000XM5', 1, 32990.00, TRUE),
    ('ORD-2026-0042', 'SKU-2045', 'Чехол для наушников',       2,  1500.00, TRUE),
    ('ORD-2026-0042', 'SKU-3378', 'Кабель USB-C 2м',           1,   690.00, FALSE),
    ('ORD-2026-0043', 'SKU-5010', 'Футболка белая L',           3,  1200.00, TRUE),
    ('ORD-2026-0044', 'SKU-1002', 'Наушники Sony WH-1000XM4',  1, 24990.00, TRUE);

INSERT INTO payments (order_id, method, total, currency, paid_at) VALUES
    ('ORD-2026-0042', 'card', 36680.00, 'RUB', '2026-03-05T14:33:12+03:00'),
    ('ORD-2026-0044', 'sbp',  24990.00, 'RUB', '2026-03-01T09:01:30+03:00');

INSERT INTO order_status_history (order_id, status, changed_by, comment) VALUES
    ('ORD-2026-0042', 'created',    'system',               NULL),
    ('ORD-2026-0042', 'paid',       'system',               'Оплата подтверждена'),
    ('ORD-2026-0042', 'processing', 'operator:ivan',        'Передан на сборку'),
    ('ORD-2026-0042', 'shipped',    'operator:ivan',        'Отгружен СДЭК'),
    ('ORD-2026-0043', 'created',    'system',               NULL),
    ('ORD-2026-0044', 'created',    'system',               NULL),
    ('ORD-2026-0044', 'paid',       'system',               'Оплата СБП'),
    ('ORD-2026-0044', 'delivered',  'system',               'Доставлен');

INSERT INTO promotions (code, type, description, discount_value, start_date, end_date, is_active) VALUES
    ('WINTER2026', 'percentage', 'Зимняя распродажа -10%', 10.00, '2026-01-01', '2026-03-31', TRUE),
    ('FIRST500',   'fixed',      'Скидка 500₽ на первый заказ', 500.00, '2026-01-01', '2026-12-31', TRUE);

INSERT INTO customer_segments (id, name, description) VALUES
    (1, 'VIP',              'Клиенты с суммой заказов > 50 000₽'),
    (2, 'Новые',            'Зарегистрированы менее 30 дней назад'),
    (3, 'Повторные покупки', 'Более 2 заказов');
SELECT setval('customer_segments_id_seq', 3);

INSERT INTO customer_segment_members (segment_id, customer_id) VALUES
    (1, 1),
    (3, 1),
    (2, 3);
