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
    (1, 'Линус Торвальдс',            'linus.torvalds@example.com',        '+358401112233', TRUE),
    (2, 'Гвидо ван Россум',           'guido.vanrossum@example.com',       '+31620123456',  TRUE),
    (3, 'Роберт Мартин',              'robert.martin@example.com',         '+13125550101',  TRUE),
    (4, 'Мартин Фаулер',              'martin.fowler@example.com',         '+447700900111', TRUE),
    (5, 'Кент Бек',                   'kent.beck@example.com',             '+14155550199',  TRUE),
    (6, 'Эндрю Таненбаум',            'andrew.tanenbaum@example.com',      '+31201234567',  FALSE);
SELECT setval('customers_id_seq', 6);

INSERT INTO categories (id, name, parent_id, sort_order) VALUES
    (1, 'Элитные китайские чаи', NULL, 1),
    (2, 'Улуны',                1,    1),
    (3, 'Пуэры',                1,    2),
    (4, 'Зеленые чаи',          1,    3),
    (5, 'IT-книги',             NULL, 2),
    (6, 'Архитектура и практики', 5, 1);
SELECT setval('categories_id_seq', 6);

INSERT INTO products (id, sku, name, description, price, category_id, brand, is_active) VALUES
    (1,  'TEA-DAHONGPAO-050',  'Да Хун Пао (50 г)',                  'Скальный улун из Уишань, насыщенный вкус с нотами карамели',       3490.00, 2, 'Wuyi Reserve', TRUE),
    (2,  'TEA-TIEGUANYIN-050', 'Те Гуань Инь Премиум (50 г)',        'Аньсийский улун с цветочным ароматом и долгим послевкусием',       2890.00, 2, 'Anxi Heritage', TRUE),
    (3,  'TEA-SHU-2018-100',   'Шу Пуэр Гунтин 2018 (100 г)',        'Выдержанный шу пуэр, плотный настой, древесно-сливочные ноты',     2590.00, 3, 'Yunnan Craft',  TRUE),
    (4,  'TEA-SHEN-2020-100',  'Шен Пуэр Бинча 2020 (100 г)',        'Молодой шен пуэр с яркой травянистостью и медовой сладостью',      3190.00, 3, 'Yunnan Craft',  TRUE),
    (5,  'TEA-LONGJING-050',   'Лунцзин Императорский (50 г)',       'Легендарный зеленый чай, ореховые ноты и мягкая сладость',         3790.00, 4, 'Hangzhou Select', TRUE),
    (6,  'BOOK-DDD',           'Domain-Driven Design',               'Eric Evans. Стратегический и тактический дизайн сложных систем',   5290.00, 6, 'Addison-Wesley', TRUE),
    (7,  'BOOK-CLEAN-CODE',    'Clean Code',                         'Robert C. Martin. Практики написания поддерживаемого кода',         4190.00, 6, 'Prentice Hall', TRUE),
    (8,  'BOOK-REF-ARCH',      'Refactoring',                        'Martin Fowler. Улучшение архитектуры существующего кода',           4590.00, 6, 'Addison-Wesley', TRUE),
    (9,  'BOOK-PYTHON',        'Python Cookbook',                    'David Beazley, Brian K. Jones. Рецепты для продвинутой разработки', 4890.00, 5, 'O Reilly Media', TRUE),
    (10, 'BOOK-LINUX',         'Just for Fun',                       'Linus Torvalds. История создания Linux и философия разработки',      2990.00, 5, 'HarperBusiness', TRUE);
SELECT setval('products_id_seq', 10);

INSERT INTO warehouses (id, name, location) VALUES
    (1, 'Главный склад', 'Москва, ул. Чайная, 8'),
    (2, 'Книжный склад', 'Санкт-Петербург, пр. Типографский, 12');
SELECT setval('warehouses_id_seq', 2);

INSERT INTO inventory (product_id, warehouse_id, quantity, min_level) VALUES
    (1, 1, 120, 15),
    (2, 1, 100, 15),
    (3, 1, 85,  10),
    (4, 1, 70,  10),
    (5, 1, 60,  10),
    (6, 2, 40,  5),
    (7, 2, 65,  8),
    (8, 2, 50,  8),
    (9, 2, 55,  8),
    (10, 2, 30, 5);

INSERT INTO addresses (customer_id, label, city, street, building, apartment, postal_code, is_default) VALUES
    (1, 'Дом',    'Хельсинки',       'Mannerheimintie',  '12',  '34', '00100', TRUE),
    (2, 'Дом',    'Амстердам',       'Prinsengracht',    '241', NULL, '1016',  TRUE),
    (3, 'Дом',    'Чикаго',          'W Madison St',     '230', '19B', '60606', TRUE),
    (4, 'Дом',    'Лондон',          'Baker Street',     '221B', NULL, 'NW1',   TRUE),
    (5, 'Коворкинг', 'Сан-Франциско','Market Street',    '201', '40', '94103', FALSE),
    (6, 'Дом',    'Амстердам',       'Damrak',           '101', '22', '1012',  TRUE);

INSERT INTO orders (order_id, customer_id, status, is_paid, comment, source, ip, tags, created_at) VALUES
    ('ORD-2026-0101', 1, 'delivered', TRUE,  'Подарочный набор для коллег', 'web',    '203.0.113.10', ARRAY['чай','подарок'],                     '2026-03-01T10:20:00+03:00'),
    ('ORD-2026-0102', 2, 'processing',TRUE,  NULL,                          'mobile', '198.51.100.24', ARRAY['книги','it'],                         '2026-03-05T12:45:00+03:00'),
    ('ORD-2026-0103', 4, 'created',   FALSE, 'Упаковать отдельно книги и чай', 'web', '192.0.2.77',   ARRAY['микс','архитектура'],                '2026-03-08T19:05:00+03:00'),
    ('ORD-2026-0104', 3, 'shipped',   TRUE,  NULL,                          'web',    '203.0.113.77', ARRAY['чай','повторный_клиент'],            '2026-03-10T09:00:00+03:00'),
    ('ORD-2026-0105', 5, 'delivered', TRUE,  'Нужна плотная упаковка книг', 'web',    '198.51.100.66', ARRAY['книги','agile'],                      '2026-03-11T11:40:00+03:00'),
    ('ORD-2026-0106', 2, 'shipped',   TRUE,  NULL,                          'mobile', '203.0.113.52', ARRAY['чай','премиум'],                      '2026-03-12T08:15:00+03:00'),
    ('ORD-2026-0107', 6, 'created',   FALSE, 'Первый заказ в магазине',     'web',    '192.0.2.43',   ARRAY['новый_клиент','микс'],                '2026-03-12T21:30:00+03:00'),
    ('ORD-2026-0108', 1, 'processing',TRUE,  NULL,                          'web',    '203.0.113.10', ARRAY['it','чай'],                           '2026-03-13T09:20:00+03:00'),
    ('ORD-2026-0109', 3, 'cancelled', FALSE, 'Отменен по просьбе клиента',  'mobile', '198.51.100.120', ARRAY['отмена'],                             '2026-03-13T17:05:00+03:00'),
    ('ORD-2026-0110', 4, 'delivered', TRUE,  NULL,                          'web',    '192.0.2.77',   ARRAY['архитектура','чай'],                  '2026-03-14T10:50:00+03:00'),
    ('ORD-2026-0111', 2, 'paid',      TRUE,  'Доставка в ближайшее окно',   'mobile', '198.51.100.24', ARRAY['чай'],                                '2026-03-15T13:25:00+03:00'),
    ('ORD-2026-0112', 5, 'shipped',   TRUE,  NULL,                          'web',    '198.51.100.66', ARRAY['книги'],                              '2026-03-16T16:40:00+03:00'),
    ('ORD-2026-0113', 1, 'created',   FALSE, 'Подтвердить перед отправкой', 'web',    '203.0.113.10', ARRAY['чай'],                                '2026-03-17T08:05:00+03:00'),
    ('ORD-2026-0114', 3, 'processing',TRUE,  NULL,                          'web',    '203.0.113.77', ARRAY['пуэр','книги'],                       '2026-03-17T19:20:00+03:00'),
    ('ORD-2026-0115', 4, 'delivered', TRUE,  'Оставить у консьержа',        'mobile', '192.0.2.77',   ARRAY['книги','clean_code'],                 '2026-03-18T12:10:00+03:00'),
    ('ORD-2026-0116', 6, 'created',   FALSE, NULL,                          'web',    '192.0.2.43',   ARRAY['чай','книги','новый_клиент'],         '2026-03-19T09:55:00+03:00'),
    ('ORD-2026-0117', 2, 'shipped',   TRUE,  NULL,                          'mobile', '198.51.100.24', ARRAY['чай','it'],                           '2026-03-19T20:15:00+03:00'),
    ('ORD-2026-0118', 5, 'delivered', TRUE,  'Подарочная открытка внутри',  'web',    '198.51.100.66', ARRAY['подарок','микс'],                     '2026-03-20T11:00:00+03:00'),
    ('ORD-2026-0119', 3, 'processing',TRUE,  NULL,                          'web',    '203.0.113.77', ARRAY['ddd','пуэр'],                         '2026-03-21T15:35:00+03:00'),
    ('ORD-2026-0120', 1, 'created',   FALSE, 'Оплата после подтверждения',  'mobile', '203.0.113.10', ARRAY['книги'],                              '2026-03-22T18:45:00+03:00');

INSERT INTO order_items (order_id, product_id, name, quantity, price, in_stock) VALUES
    ('ORD-2026-0101', 'TEA-DAHONGPAO-050',  'Да Хун Пао (50 г)',            2, 3490.00, TRUE),
    ('ORD-2026-0101', 'TEA-TIEGUANYIN-050', 'Те Гуань Инь Премиум (50 г)',  1, 2890.00, TRUE),
    ('ORD-2026-0102', 'BOOK-PYTHON',        'Python Cookbook',               1, 4890.00, TRUE),
    ('ORD-2026-0102', 'BOOK-CLEAN-CODE',    'Clean Code',                    1, 4190.00, TRUE),
    ('ORD-2026-0103', 'BOOK-REF-ARCH',      'Refactoring',                   1, 4590.00, TRUE),
    ('ORD-2026-0103', 'TEA-LONGJING-050',   'Лунцзин Императорский (50 г)',  1, 3790.00, TRUE),
    ('ORD-2026-0104', 'TEA-SHU-2018-100',   'Шу Пуэр Гунтин 2018 (100 г)',   3, 2590.00, TRUE),
    ('ORD-2026-0104', 'BOOK-DDD',           'Domain-Driven Design',          1, 5290.00, TRUE),
    ('ORD-2026-0105', 'BOOK-CLEAN-CODE',    'Clean Code',                    1, 4190.00, TRUE),
    ('ORD-2026-0105', 'BOOK-REF-ARCH',      'Refactoring',                   1, 4590.00, TRUE),
    ('ORD-2026-0106', 'TEA-LONGJING-050',   'Лунцзин Императорский (50 г)',  2, 3790.00, TRUE),
    ('ORD-2026-0106', 'TEA-TIEGUANYIN-050', 'Те Гуань Инь Премиум (50 г)',  1, 2890.00, TRUE),
    ('ORD-2026-0107', 'BOOK-LINUX',         'Just for Fun',                  1, 2990.00, TRUE),
    ('ORD-2026-0107', 'TEA-SHU-2018-100',   'Шу Пуэр Гунтин 2018 (100 г)',   1, 2590.00, TRUE),
    ('ORD-2026-0108', 'BOOK-DDD',           'Domain-Driven Design',          1, 5290.00, TRUE),
    ('ORD-2026-0108', 'BOOK-PYTHON',        'Python Cookbook',               1, 4890.00, TRUE),
    ('ORD-2026-0108', 'TEA-DAHONGPAO-050',  'Да Хун Пао (50 г)',             1, 3490.00, TRUE),
    ('ORD-2026-0109', 'TEA-SHEN-2020-100',  'Шен Пуэр Бинча 2020 (100 г)',   2, 3190.00, TRUE),
    ('ORD-2026-0109', 'BOOK-CLEAN-CODE',    'Clean Code',                    1, 4190.00, TRUE),
    ('ORD-2026-0110', 'TEA-LONGJING-050',   'Лунцзин Императорский (50 г)',  1, 3790.00, TRUE),
    ('ORD-2026-0110', 'BOOK-REF-ARCH',      'Refactoring',                   1, 4590.00, TRUE),
    ('ORD-2026-0110', 'BOOK-DDD',           'Domain-Driven Design',          1, 5290.00, TRUE),
    ('ORD-2026-0111', 'TEA-DAHONGPAO-050',  'Да Хун Пао (50 г)',             3, 3490.00, TRUE),
    ('ORD-2026-0111', 'TEA-SHU-2018-100',   'Шу Пуэр Гунтин 2018 (100 г)',   1, 2590.00, TRUE),
    ('ORD-2026-0112', 'BOOK-CLEAN-CODE',    'Clean Code',                    2, 4190.00, TRUE),
    ('ORD-2026-0112', 'BOOK-PYTHON',        'Python Cookbook',               1, 4890.00, TRUE),
    ('ORD-2026-0113', 'TEA-TIEGUANYIN-050', 'Те Гуань Инь Премиум (50 г)',  2, 2890.00, TRUE),
    ('ORD-2026-0114', 'TEA-SHU-2018-100',   'Шу Пуэр Гунтин 2018 (100 г)',   2, 2590.00, TRUE),
    ('ORD-2026-0114', 'TEA-SHEN-2020-100',  'Шен Пуэр Бинча 2020 (100 г)',   1, 3190.00, TRUE),
    ('ORD-2026-0114', 'BOOK-LINUX',         'Just for Fun',                  1, 2990.00, TRUE),
    ('ORD-2026-0115', 'BOOK-DDD',           'Domain-Driven Design',          1, 5290.00, TRUE),
    ('ORD-2026-0115', 'BOOK-CLEAN-CODE',    'Clean Code',                    1, 4190.00, TRUE),
    ('ORD-2026-0116', 'TEA-LONGJING-050',   'Лунцзин Императорский (50 г)',  1, 3790.00, TRUE),
    ('ORD-2026-0116', 'TEA-DAHONGPAO-050',  'Да Хун Пао (50 г)',             1, 3490.00, TRUE),
    ('ORD-2026-0116', 'BOOK-LINUX',         'Just for Fun',                  1, 2990.00, TRUE),
    ('ORD-2026-0117', 'TEA-SHEN-2020-100',  'Шен Пуэр Бинча 2020 (100 г)',   2, 3190.00, TRUE),
    ('ORD-2026-0117', 'TEA-TIEGUANYIN-050', 'Те Гуань Инь Премиум (50 г)',  1, 2890.00, TRUE),
    ('ORD-2026-0117', 'BOOK-PYTHON',        'Python Cookbook',               1, 4890.00, TRUE),
    ('ORD-2026-0118', 'TEA-DAHONGPAO-050',  'Да Хун Пао (50 г)',             1, 3490.00, TRUE),
    ('ORD-2026-0118', 'TEA-LONGJING-050',   'Лунцзин Императорский (50 г)',  1, 3790.00, TRUE),
    ('ORD-2026-0118', 'BOOK-REF-ARCH',      'Refactoring',                   1, 4590.00, TRUE),
    ('ORD-2026-0119', 'BOOK-CLEAN-CODE',    'Clean Code',                    1, 4190.00, TRUE),
    ('ORD-2026-0119', 'BOOK-DDD',           'Domain-Driven Design',          1, 5290.00, TRUE),
    ('ORD-2026-0119', 'TEA-SHU-2018-100',   'Шу Пуэр Гунтин 2018 (100 г)',   1, 2590.00, TRUE),
    ('ORD-2026-0120', 'BOOK-PYTHON',        'Python Cookbook',               1, 4890.00, TRUE),
    ('ORD-2026-0120', 'BOOK-LINUX',         'Just for Fun',                  1, 2990.00, TRUE);

INSERT INTO payments (order_id, method, total, currency, paid_at) VALUES
    ('ORD-2026-0101', 'card',  9870.00, 'RUB', '2026-03-01T10:21:20+03:00'),
    ('ORD-2026-0102', 'sbp',   9080.00, 'RUB', '2026-03-05T12:47:01+03:00'),
    ('ORD-2026-0104', 'wallet',13060.00, 'RUB', '2026-03-10T09:02:11+03:00'),
    ('ORD-2026-0105', 'card',   8780.00, 'RUB', '2026-03-11T11:42:10+03:00'),
    ('ORD-2026-0106', 'sbp',   10470.00, 'RUB', '2026-03-12T08:16:31+03:00'),
    ('ORD-2026-0108', 'wallet',13670.00, 'RUB', '2026-03-13T09:21:05+03:00'),
    ('ORD-2026-0110', 'card',  13670.00, 'RUB', '2026-03-14T10:52:42+03:00'),
    ('ORD-2026-0111', 'sbp',   13060.00, 'RUB', '2026-03-15T13:26:09+03:00'),
    ('ORD-2026-0112', 'card',  13270.00, 'RUB', '2026-03-16T16:42:50+03:00'),
    ('ORD-2026-0114', 'wallet',11360.00, 'RUB', '2026-03-17T19:21:28+03:00'),
    ('ORD-2026-0115', 'card',   9480.00, 'RUB', '2026-03-18T12:11:47+03:00'),
    ('ORD-2026-0117', 'sbp',   14160.00, 'RUB', '2026-03-19T20:16:34+03:00'),
    ('ORD-2026-0118', 'card',  11870.00, 'RUB', '2026-03-20T11:01:13+03:00'),
    ('ORD-2026-0119', 'wallet',12070.00, 'RUB', '2026-03-21T15:37:02+03:00');

INSERT INTO order_status_history (order_id, status, changed_by, comment) VALUES
    ('ORD-2026-0101', 'created',    'system',              NULL),
    ('ORD-2026-0101', 'paid',       'system',              'Оплата банковской картой'),
    ('ORD-2026-0101', 'processing', 'operator:tea_master', 'Передан в отдел фасовки'),
    ('ORD-2026-0101', 'shipped',    'operator:tea_master', 'Отправлен DHL'),
    ('ORD-2026-0101', 'delivered',  'system',              'Доставлен получателю'),
    ('ORD-2026-0102', 'created',    'system',              NULL),
    ('ORD-2026-0102', 'paid',       'system',              'Оплата СБП'),
    ('ORD-2026-0102', 'processing', 'operator:book_team',  'Комплектация на книжном складе'),
    ('ORD-2026-0103', 'created',    'system',              NULL),
    ('ORD-2026-0104', 'created',    'system',              NULL),
    ('ORD-2026-0104', 'paid',       'system',              'Оплачено из кошелька'),
    ('ORD-2026-0104', 'processing', 'operator:tea_master', 'Сформирован набор пуэров'),
    ('ORD-2026-0104', 'shipped',    'operator:tea_master', 'Передан в доставку'),
    ('ORD-2026-0105', 'created',    'system',              NULL),
    ('ORD-2026-0105', 'paid',       'system',              'Оплата банковской картой'),
    ('ORD-2026-0105', 'processing', 'operator:book_team',  'Книги упакованы'),
    ('ORD-2026-0105', 'shipped',    'operator:book_team',  'Передан в службу доставки'),
    ('ORD-2026-0105', 'delivered',  'system',              'Заказ доставлен'),
    ('ORD-2026-0106', 'created',    'system',              NULL),
    ('ORD-2026-0106', 'paid',       'system',              'Оплата СБП'),
    ('ORD-2026-0106', 'processing', 'operator:tea_master', 'Фасовка выполнена'),
    ('ORD-2026-0106', 'shipped',    'operator:tea_master', 'Передан курьеру'),
    ('ORD-2026-0107', 'created',    'system',              NULL),
    ('ORD-2026-0108', 'created',    'system',              NULL),
    ('ORD-2026-0108', 'paid',       'system',              'Оплата с внутреннего кошелька'),
    ('ORD-2026-0108', 'processing', 'operator:book_team',  'Ожидает комплектования'),
    ('ORD-2026-0109', 'created',    'system',              NULL),
    ('ORD-2026-0109', 'cancelled',  'operator:support',    'Отменено до оплаты'),
    ('ORD-2026-0110', 'created',    'system',              NULL),
    ('ORD-2026-0110', 'paid',       'system',              'Оплата картой'),
    ('ORD-2026-0110', 'processing', 'operator:book_team',  'Комплектация завершена'),
    ('ORD-2026-0110', 'shipped',    'operator:book_team',  'Отправлен UPS'),
    ('ORD-2026-0110', 'delivered',  'system',              'Получен адресатом'),
    ('ORD-2026-0111', 'created',    'system',              NULL),
    ('ORD-2026-0111', 'paid',       'system',              'Заказ оплачен'),
    ('ORD-2026-0112', 'created',    'system',              NULL),
    ('ORD-2026-0112', 'paid',       'system',              'Оплата картой'),
    ('ORD-2026-0112', 'processing', 'operator:book_team',  'Передан на отгрузку'),
    ('ORD-2026-0112', 'shipped',    'operator:book_team',  'Отправлен'),
    ('ORD-2026-0113', 'created',    'system',              NULL),
    ('ORD-2026-0114', 'created',    'system',              NULL),
    ('ORD-2026-0114', 'paid',       'system',              'Оплата подтверждена'),
    ('ORD-2026-0114', 'processing', 'operator:tea_master', 'Сборка чайного набора'),
    ('ORD-2026-0115', 'created',    'system',              NULL),
    ('ORD-2026-0115', 'paid',       'system',              'Оплата картой'),
    ('ORD-2026-0115', 'processing', 'operator:book_team',  'Подготовка к отправке'),
    ('ORD-2026-0115', 'shipped',    'operator:book_team',  'Передан курьеру'),
    ('ORD-2026-0115', 'delivered',  'system',              'Вручено клиенту'),
    ('ORD-2026-0116', 'created',    'system',              NULL),
    ('ORD-2026-0117', 'created',    'system',              NULL),
    ('ORD-2026-0117', 'paid',       'system',              'СБП оплата прошла'),
    ('ORD-2026-0117', 'processing', 'operator:tea_master', 'Заказ собран'),
    ('ORD-2026-0117', 'shipped',    'operator:tea_master', 'Передан в доставку'),
    ('ORD-2026-0118', 'created',    'system',              NULL),
    ('ORD-2026-0118', 'paid',       'system',              'Оплата картой'),
    ('ORD-2026-0118', 'processing', 'operator:tea_master', 'Подарочная упаковка'),
    ('ORD-2026-0118', 'shipped',    'operator:tea_master', 'Отправлен'),
    ('ORD-2026-0118', 'delivered',  'system',              'Доставлен в срок'),
    ('ORD-2026-0119', 'created',    'system',              NULL),
    ('ORD-2026-0119', 'paid',       'system',              'Оплата кошельком'),
    ('ORD-2026-0119', 'processing', 'operator:book_team',  'Комплектация продолжается'),
    ('ORD-2026-0120', 'created',    'system',              NULL);

INSERT INTO promotions (id, code, type, description, discount_value, min_order_sum, start_date, end_date, is_active) VALUES
    (1, 'TEA10',        'percentage', 'Скидка 10% на элитные китайские чаи', 10.00, 3000.00, '2026-01-01', '2026-12-31', TRUE),
    (2, 'BOOK5000',     'fixed',      'Скидка 700₽ на IT-книги от 5000₽',   700.00, 5000.00, '2026-01-01', '2026-12-31', TRUE),
    (3, 'COMBO-TEA-IT', 'free_shipping', 'Бесплатная доставка на комбо из чая и книг', 0.00, 6000.00, '2026-02-01', '2026-12-31', TRUE);
SELECT setval('promotions_id_seq', 3);

INSERT INTO promotion_products (promotion_id, product_id) VALUES
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
    (2, 6), (2, 7), (2, 8), (2, 9), (2, 10),
    (3, 2), (3, 7), (3, 8);

INSERT INTO customer_segments (id, name, description) VALUES
    (1, 'Чайные гурманы',      'Клиенты, регулярно покупающие элитные китайские чаи'),
    (2, 'IT-читатели',         'Покупатели профессиональной IT-литературы'),
    (3, 'Коллекционеры знаний','Покупают и чай, и профильные IT-книги'),
    (4, 'Новые клиенты',       'Первые 30 дней после регистрации');
SELECT setval('customer_segments_id_seq', 4);

INSERT INTO customer_segment_members (segment_id, customer_id) VALUES
    (1, 1),
    (1, 3),
    (2, 2),
    (2, 4),
    (3, 1),
    (3, 4),
    (4, 6);
