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

-- ======================== MET ========================

CREATE TABLE metadata_data_assets (
    id                SERIAL       PRIMARY KEY,
    schema_name       VARCHAR(63)  NOT NULL,
    object_name       VARCHAR(128) NOT NULL,
    object_type       VARCHAR(20)  NOT NULL
                      CHECK (object_type IN ('table','view','materialized_view')),
    dama_type         VARCHAR(30)  NOT NULL
                      CHECK (dama_type IN ('Master Data','Transactional','Reference','Metadata','Analytical')),
    business_owner    VARCHAR(100),
    data_steward      VARCHAR(100),
    description       TEXT,
    refresh_frequency VARCHAR(50),
    contains_pii      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (schema_name, object_name, object_type)
);

CREATE TABLE metadata_data_elements (
    id                  SERIAL       PRIMARY KEY,
    asset_id            INTEGER      NOT NULL REFERENCES metadata_data_assets(id) ON DELETE CASCADE,
    column_name         VARCHAR(128) NOT NULL,
    logical_name        VARCHAR(255),
    business_definition TEXT,
    source_system       VARCHAR(100),
    is_nullable         BOOLEAN,
    pii_class           VARCHAR(20)  NOT NULL DEFAULT 'none'
                        CHECK (pii_class IN ('none','low','medium','high')),
    sample_format       VARCHAR(255),
    dq_expectation      TEXT,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (asset_id, column_name)
);

CREATE TABLE metadata_data_quality_rules (
    id             SERIAL       PRIMARY KEY,
    asset_id       INTEGER      NOT NULL REFERENCES metadata_data_assets(id) ON DELETE CASCADE,
    column_name    VARCHAR(128),
    rule_name      VARCHAR(150) NOT NULL,
    rule_type      VARCHAR(30)  NOT NULL
                   CHECK (rule_type IN ('completeness','validity','uniqueness','consistency','timeliness','integrity')),
    rule_sql       TEXT         NOT NULL,
    severity       VARCHAR(20)  NOT NULL DEFAULT 'warning'
                   CHECK (severity IN ('info','warning','critical')),
    threshold_pct  NUMERIC(5,2),
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_metadata_assets_dama_type    ON metadata_data_assets(dama_type);
CREATE INDEX idx_metadata_elements_asset      ON metadata_data_elements(asset_id);
CREATE INDEX idx_metadata_rules_asset         ON metadata_data_quality_rules(asset_id);
CREATE INDEX idx_metadata_rules_active        ON metadata_data_quality_rules(is_active);

-- ============================================================
-- Documentation (table and column descriptions)
-- ============================================================

-- ACC
COMMENT ON TABLE customers IS '[DAMA-DMBOK: Master Data] Покупатели интернет-магазина: базовый профиль клиента, контактные данные и статус верификации.';
COMMENT ON COLUMN customers.id IS 'Уникальный идентификатор покупателя (PK). Используется как ссылка во всех связанных таблицах.';
COMMENT ON COLUMN customers.name IS 'Имя и фамилия покупателя, отображается в личном кабинете, заказах и поддержке.';
COMMENT ON COLUMN customers.email IS 'Основной email покупателя. Уникален, используется для входа, уведомлений и чеков.';
COMMENT ON COLUMN customers.phone IS 'Контактный телефон для доставки, подтверждений и связи службы поддержки.';
COMMENT ON COLUMN customers.password_hash IS 'Хеш пароля (никогда не хранить пароль в открытом виде). Может быть NULL для внешней авторизации.';
COMMENT ON COLUMN customers.is_verified IS 'Признак подтверждения аккаунта (email/телефон). TRUE — профиль подтвержден.';
COMMENT ON COLUMN customers.created_at IS 'Дата и время регистрации покупателя.';

COMMENT ON TABLE addresses IS '[DAMA-DMBOK: Master Data] Адреса доставки покупателей. Один покупатель может иметь несколько адресов (дом, офис и т.д.).';
COMMENT ON COLUMN addresses.id IS 'Уникальный идентификатор адреса (PK).';
COMMENT ON COLUMN addresses.customer_id IS 'Ссылка на владельца адреса (customers.id). При удалении клиента адрес удаляется каскадно.';
COMMENT ON COLUMN addresses.label IS 'Пользовательская метка адреса: например, "Дом", "Офис", "Склад".';
COMMENT ON COLUMN addresses.city IS 'Город доставки.';
COMMENT ON COLUMN addresses.street IS 'Улица доставки.';
COMMENT ON COLUMN addresses.building IS 'Номер дома/корпуса.';
COMMENT ON COLUMN addresses.apartment IS 'Квартира/офис/помещение. Может быть NULL.';
COMMENT ON COLUMN addresses.postal_code IS 'Почтовый индекс адреса.';
COMMENT ON COLUMN addresses.country_code IS 'Код страны в формате ISO 3166-1 alpha-2 (например, RU, US, NL).';
COMMENT ON COLUMN addresses.is_default IS 'Признак адреса по умолчанию для покупателя.';
COMMENT ON COLUMN addresses.created_at IS 'Дата и время добавления адреса.';

-- CAT
COMMENT ON TABLE categories IS '[DAMA-DMBOK: Reference Data] Категории каталога товаров. Поддерживается иерархия через parent_id.';
COMMENT ON COLUMN categories.id IS 'Уникальный идентификатор категории (PK).';
COMMENT ON COLUMN categories.name IS 'Название категории, отображаемое в каталоге и фильтрах.';
COMMENT ON COLUMN categories.parent_id IS 'Ссылка на родительскую категорию (self-reference). NULL означает корневую категорию.';
COMMENT ON COLUMN categories.sort_order IS 'Порядок сортировки категории в меню/каталоге (меньше — выше).';
COMMENT ON COLUMN categories.is_active IS 'Признак активности категории. Неактивные категории можно скрывать на витрине.';

COMMENT ON TABLE products IS '[DAMA-DMBOK: Master Data] Каталог товаров магазина: чай, книги и другие позиции, доступные к продаже.';
COMMENT ON COLUMN products.id IS 'Уникальный идентификатор товара (PK).';
COMMENT ON COLUMN products.sku IS 'Уникальный артикул товара (Stock Keeping Unit), используется в операционном учете.';
COMMENT ON COLUMN products.name IS 'Название товара, отображаемое на витрине и в заказах.';
COMMENT ON COLUMN products.description IS 'Подробное текстовое описание товара: состав, характеристики, особенности.';
COMMENT ON COLUMN products.price IS 'Базовая цена товара в валюте магазина. Не может быть отрицательной.';
COMMENT ON COLUMN products.category_id IS 'Ссылка на категорию товара (categories.id).';
COMMENT ON COLUMN products.brand IS 'Бренд/издательство/производитель товара.';
COMMENT ON COLUMN products.image_url IS 'URL основного изображения товара для витрины.';
COMMENT ON COLUMN products.is_active IS 'Признак доступности товара на витрине. FALSE — товар скрыт от покупки.';
COMMENT ON COLUMN products.created_at IS 'Дата и время создания карточки товара.';
COMMENT ON COLUMN products.updated_at IS 'Дата и время последнего обновления карточки товара.';

-- INV
COMMENT ON TABLE warehouses IS '[DAMA-DMBOK: Master Data] Справочник складов хранения товаров. Нужны для учета остатков и логистики.';
COMMENT ON COLUMN warehouses.id IS 'Уникальный идентификатор склада (PK).';
COMMENT ON COLUMN warehouses.name IS 'Человеко-читаемое название склада.';
COMMENT ON COLUMN warehouses.location IS 'Адрес/описание расположения склада.';

COMMENT ON TABLE inventory IS '[DAMA-DMBOK: Transactional Data] Операционные остатки товаров по складам (складской учет), изменяются в ходе бизнес-процессов.';
COMMENT ON COLUMN inventory.id IS 'Уникальный идентификатор записи остатка (PK).';
COMMENT ON COLUMN inventory.product_id IS 'Ссылка на товар (products.id).';
COMMENT ON COLUMN inventory.warehouse_id IS 'Ссылка на склад (warehouses.id).';
COMMENT ON COLUMN inventory.quantity IS 'Текущее доступное количество товара на складе.';
COMMENT ON COLUMN inventory.min_level IS 'Минимальный рекомендуемый уровень остатка для сигнала на пополнение.';
COMMENT ON COLUMN inventory.updated_at IS 'Дата и время последнего обновления остатка.';

-- CRT
COMMENT ON TABLE carts IS '[DAMA-DMBOK: Transactional Data] Корзины покупок. Могут быть привязаны к авторизованному пользователю или гостевой сессии.';
COMMENT ON COLUMN carts.id IS 'Уникальный идентификатор корзины (PK).';
COMMENT ON COLUMN carts.customer_id IS 'Ссылка на покупателя (customers.id). NULL для гостевой корзины.';
COMMENT ON COLUMN carts.session_id IS 'Идентификатор гостевой сессии/браузера для неавторизованных корзин.';
COMMENT ON COLUMN carts.created_at IS 'Дата и время создания корзины.';
COMMENT ON COLUMN carts.updated_at IS 'Дата и время последнего изменения корзины.';

COMMENT ON TABLE cart_items IS '[DAMA-DMBOK: Transactional Data] Позиции в корзине: какой товар и в каком количестве добавлен.';
COMMENT ON COLUMN cart_items.id IS 'Уникальный идентификатор позиции корзины (PK).';
COMMENT ON COLUMN cart_items.cart_id IS 'Ссылка на корзину (carts.id). При удалении корзины позиции удаляются каскадно.';
COMMENT ON COLUMN cart_items.product_id IS 'Ссылка на товар (products.id), добавленный в корзину.';
COMMENT ON COLUMN cart_items.quantity IS 'Количество единиц товара в данной позиции корзины.';

-- ORD / CHK
COMMENT ON TABLE orders IS '[DAMA-DMBOK: Transactional Data] Заказы покупателей: шапка заказа со статусом, источником, метаинформацией и признаком оплаты.';
COMMENT ON COLUMN orders.order_id IS 'Бизнес-идентификатор заказа (PK), читаемый номер в формате ORD-...';
COMMENT ON COLUMN orders.customer_id IS 'Ссылка на покупателя, оформившего заказ (customers.id).';
COMMENT ON COLUMN orders.status IS 'Текущий статус жизненного цикла заказа (created/paid/processing/shipped/delivered/cancelled).';
COMMENT ON COLUMN orders.is_paid IS 'Признак оплаты заказа. TRUE, если заказ оплачен полностью.';
COMMENT ON COLUMN orders.comment IS 'Комментарий к заказу от клиента/оператора (особые пожелания, уточнения).';
COMMENT ON COLUMN orders.source IS 'Канал оформления заказа: web, mobile и т.д.';
COMMENT ON COLUMN orders.ip IS 'IP-адрес клиента в момент оформления заказа (для аналитики/антифрода).';
COMMENT ON COLUMN orders.tags IS 'Набор тегов заказа для сегментации и аналитики.';
COMMENT ON COLUMN orders.created_at IS 'Дата и время создания заказа.';
COMMENT ON COLUMN orders.updated_at IS 'Дата и время последнего обновления заказа.';

COMMENT ON TABLE order_items IS '[DAMA-DMBOK: Transactional Data] Позиции заказа (snapshot): фиксируют товар, имя и цену на момент покупки.';
COMMENT ON COLUMN order_items.id IS 'Уникальный идентификатор позиции заказа (PK).';
COMMENT ON COLUMN order_items.order_id IS 'Ссылка на заказ (orders.order_id).';
COMMENT ON COLUMN order_items.product_id IS 'Артикул/идентификатор товарной позиции на момент заказа (хранится как строка).';
COMMENT ON COLUMN order_items.name IS 'Название товара на момент покупки (исторический снимок, не зависит от текущего названия в каталоге).';
COMMENT ON COLUMN order_items.quantity IS 'Количество единиц товара в заказе.';
COMMENT ON COLUMN order_items.price IS 'Цена за единицу товара на момент оформления заказа.';
COMMENT ON COLUMN order_items.in_stock IS 'Флаг наличия товара в момент обработки/комплектации позиции.';

COMMENT ON TABLE payments IS '[DAMA-DMBOK: Transactional Data] Платежные операции по заказам.';
COMMENT ON COLUMN payments.id IS 'Уникальный идентификатор платежа (PK).';
COMMENT ON COLUMN payments.order_id IS 'Ссылка на заказ, к которому относится платеж (orders.order_id).';
COMMENT ON COLUMN payments.method IS 'Метод оплаты: card, cash, sbp, wallet.';
COMMENT ON COLUMN payments.total IS 'Итоговая сумма платежа.';
COMMENT ON COLUMN payments.currency IS 'Валюта платежа в формате ISO 4217 (например, RUB, USD).';
COMMENT ON COLUMN payments.paid_at IS 'Дата и время подтверждения оплаты. NULL, если платеж не завершен.';

COMMENT ON TABLE order_status_history IS '[DAMA-DMBOK: Transactional Data] История переходов статусов заказа (audit trail процесса исполнения).';
COMMENT ON COLUMN order_status_history.id IS 'Уникальный идентификатор записи истории (PK).';
COMMENT ON COLUMN order_status_history.order_id IS 'Ссылка на заказ (orders.order_id), статус которого изменился.';
COMMENT ON COLUMN order_status_history.status IS 'Новый статус заказа, установленный в момент записи.';
COMMENT ON COLUMN order_status_history.changed_at IS 'Дата и время смены статуса.';
COMMENT ON COLUMN order_status_history.changed_by IS 'Источник изменения: system, оператор, интеграция и т.д.';
COMMENT ON COLUMN order_status_history.comment IS 'Служебный комментарий к смене статуса.';

-- MKT
COMMENT ON TABLE promotions IS '[DAMA-DMBOK: Reference Data] Маркетинговые акции и промокоды (скидки, фиксированная скидка, бесплатная доставка) как управляемые правила применения.';
COMMENT ON COLUMN promotions.id IS 'Уникальный идентификатор акции (PK).';
COMMENT ON COLUMN promotions.code IS 'Уникальный промокод, который вводит пользователь при оформлении.';
COMMENT ON COLUMN promotions.type IS 'Тип акции: percentage, fixed, free_shipping.';
COMMENT ON COLUMN promotions.description IS 'Текстовое описание условий акции.';
COMMENT ON COLUMN promotions.discount_value IS 'Значение скидки: процент или фиксированная сумма (в зависимости от type).';
COMMENT ON COLUMN promotions.min_order_sum IS 'Минимальная сумма заказа для применения акции.';
COMMENT ON COLUMN promotions.start_date IS 'Дата и время начала действия акции.';
COMMENT ON COLUMN promotions.end_date IS 'Дата и время окончания действия акции.';
COMMENT ON COLUMN promotions.is_active IS 'Признак активности акции (вкл/выкл вручную).';

COMMENT ON TABLE promotion_products IS '[DAMA-DMBOK: Reference Data] Связь many-to-many между акциями и товарами, для которых акция действует.';
COMMENT ON COLUMN promotion_products.promotion_id IS 'Ссылка на акцию (promotions.id).';
COMMENT ON COLUMN promotion_products.product_id IS 'Ссылка на товар (products.id), участвующий в акции.';

-- SUP
COMMENT ON TABLE support_tickets IS '[DAMA-DMBOK: Transactional Data] Тикеты службы поддержки: обращения клиентов по заказам, оплате, доставке и товарам.';
COMMENT ON COLUMN support_tickets.id IS 'Уникальный идентификатор тикета (PK).';
COMMENT ON COLUMN support_tickets.customer_id IS 'Ссылка на клиента-автора обращения (customers.id).';
COMMENT ON COLUMN support_tickets.subject IS 'Тема обращения.';
COMMENT ON COLUMN support_tickets.message IS 'Подробный текст обращения клиента.';
COMMENT ON COLUMN support_tickets.status IS 'Статус обработки тикета: open, in_progress, resolved, closed.';
COMMENT ON COLUMN support_tickets.created_at IS 'Дата и время создания тикета.';
COMMENT ON COLUMN support_tickets.updated_at IS 'Дата и время последнего изменения тикета.';

-- CLI
COMMENT ON TABLE customer_segments IS '[DAMA-DMBOK: Reference Data] Сегменты клиентов для аналитики, маркетинга и персонализации как управляемый справочник.';
COMMENT ON COLUMN customer_segments.id IS 'Уникальный идентификатор сегмента (PK).';
COMMENT ON COLUMN customer_segments.name IS 'Уникальное название сегмента.';
COMMENT ON COLUMN customer_segments.description IS 'Описание логики сегментации и назначения сегмента.';

COMMENT ON TABLE customer_segment_members IS '[DAMA-DMBOK: Reference Data] Состав сегментов: какие клиенты входят в какие сегменты.';
COMMENT ON COLUMN customer_segment_members.segment_id IS 'Ссылка на сегмент (customer_segments.id).';
COMMENT ON COLUMN customer_segment_members.customer_id IS 'Ссылка на клиента (customers.id), входящего в сегмент.';

-- MET
COMMENT ON TABLE metadata_data_assets IS '[DAMA-DMBOK: Metadata] Реестр объектов данных (таблицы, view, materialized view) с классификацией и владельцами.';
COMMENT ON COLUMN metadata_data_assets.id IS 'Уникальный идентификатор мета-объекта (PK).';
COMMENT ON COLUMN metadata_data_assets.schema_name IS 'Имя схемы БД, где расположен объект данных.';
COMMENT ON COLUMN metadata_data_assets.object_name IS 'Имя объекта данных (таблица, view, materialized view).';
COMMENT ON COLUMN metadata_data_assets.object_type IS 'Тип объекта данных: table, view, materialized_view.';
COMMENT ON COLUMN metadata_data_assets.dama_type IS 'Классификация объекта по DAMA-DMBOK: Master/Transactional/Reference/Metadata/Analytical.';
COMMENT ON COLUMN metadata_data_assets.business_owner IS 'Бизнес-владелец данных (роль или подразделение).';
COMMENT ON COLUMN metadata_data_assets.data_steward IS 'Ответственный за качество и управление данными (data steward).';
COMMENT ON COLUMN metadata_data_assets.description IS 'Бизнес-описание назначения объекта.';
COMMENT ON COLUMN metadata_data_assets.refresh_frequency IS 'Периодичность обновления данных (real-time, hourly, daily и т.д.).';
COMMENT ON COLUMN metadata_data_assets.contains_pii IS 'Признак наличия персональных данных (PII) в объекте.';
COMMENT ON COLUMN metadata_data_assets.created_at IS 'Дата и время создания записи в реестре метаданных.';
COMMENT ON COLUMN metadata_data_assets.updated_at IS 'Дата и время последнего обновления записи в реестре метаданных.';

COMMENT ON TABLE metadata_data_elements IS '[DAMA-DMBOK: Metadata] Словарь элементов данных (атрибутов/колонок) с бизнес-определениями и PII-классом.';
COMMENT ON COLUMN metadata_data_elements.id IS 'Уникальный идентификатор элемента данных (PK).';
COMMENT ON COLUMN metadata_data_elements.asset_id IS 'Ссылка на объект данных из metadata_data_assets.';
COMMENT ON COLUMN metadata_data_elements.column_name IS 'Физическое имя колонки в БД.';
COMMENT ON COLUMN metadata_data_elements.logical_name IS 'Логическое (человеко-читаемое) имя атрибута.';
COMMENT ON COLUMN metadata_data_elements.business_definition IS 'Бизнес-определение смысла атрибута.';
COMMENT ON COLUMN metadata_data_elements.source_system IS 'Система-источник, из которой поступает значение атрибута.';
COMMENT ON COLUMN metadata_data_elements.is_nullable IS 'Признак допуска NULL в колонке (по структуре объекта).';
COMMENT ON COLUMN metadata_data_elements.pii_class IS 'Класс чувствительности персональных данных: none/low/medium/high.';
COMMENT ON COLUMN metadata_data_elements.sample_format IS 'Типовой формат значения (пример шаблона: email, UUID, ISO date).';
COMMENT ON COLUMN metadata_data_elements.dq_expectation IS 'Ожидание по качеству данных для данного атрибута.';
COMMENT ON COLUMN metadata_data_elements.created_at IS 'Дата и время создания записи по атрибуту.';
COMMENT ON COLUMN metadata_data_elements.updated_at IS 'Дата и время последнего обновления записи по атрибуту.';

COMMENT ON TABLE metadata_data_quality_rules IS '[DAMA-DMBOK: Metadata] Каталог правил качества данных (DQ rules) для объектов и их атрибутов.';
COMMENT ON COLUMN metadata_data_quality_rules.id IS 'Уникальный идентификатор правила качества данных (PK).';
COMMENT ON COLUMN metadata_data_quality_rules.asset_id IS 'Ссылка на объект данных, к которому относится правило.';
COMMENT ON COLUMN metadata_data_quality_rules.column_name IS 'Колонка, к которой применяется правило; NULL, если правило объектного уровня.';
COMMENT ON COLUMN metadata_data_quality_rules.rule_name IS 'Краткое название правила качества данных.';
COMMENT ON COLUMN metadata_data_quality_rules.rule_type IS 'Тип правила качества: completeness, validity, uniqueness, consistency, timeliness, integrity.';
COMMENT ON COLUMN metadata_data_quality_rules.rule_sql IS 'SQL-выражение проверки качества данных.';
COMMENT ON COLUMN metadata_data_quality_rules.severity IS 'Критичность нарушения правила: info, warning, critical.';
COMMENT ON COLUMN metadata_data_quality_rules.threshold_pct IS 'Порог допустимой доли нарушений в процентах.';
COMMENT ON COLUMN metadata_data_quality_rules.is_active IS 'Признак активности правила качества.';
COMMENT ON COLUMN metadata_data_quality_rules.created_at IS 'Дата и время создания правила.';
COMMENT ON COLUMN metadata_data_quality_rules.updated_at IS 'Дата и время последнего обновления правила.';


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

-- ============================================================
-- Analytical Layer (DAMA-DMBOK: Analytical Data)
-- ============================================================

CREATE SCHEMA analytics;
COMMENT ON SCHEMA analytics IS 'Аналитический слой (витрины и агрегаты) для BI и управленческой отчетности.';

CREATE VIEW analytics.sales_daily AS
SELECT
    DATE_TRUNC('day', o.created_at)::date AS order_date,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.status <> 'cancelled') AS orders_total,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.is_paid) AS paid_orders,
    COALESCE(SUM(CASE WHEN o.is_paid THEN oi.quantity ELSE 0 END), 0)::bigint AS items_sold,
    COALESCE(SUM(CASE WHEN o.is_paid THEN oi.quantity * oi.price ELSE 0 END), 0)::NUMERIC(14,2) AS gross_revenue
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY 1;

COMMENT ON VIEW analytics.sales_daily IS '[DAMA-DMBOK: Analytical Data] Дневная витрина продаж: количество заказов, оплаченные заказы, проданные единицы, валовая выручка.';
COMMENT ON COLUMN analytics.sales_daily.order_date IS 'Календарная дата заказа.';
COMMENT ON COLUMN analytics.sales_daily.orders_total IS 'Количество заказов за дату, исключая отмененные.';
COMMENT ON COLUMN analytics.sales_daily.paid_orders IS 'Количество оплаченных заказов за дату.';
COMMENT ON COLUMN analytics.sales_daily.items_sold IS 'Количество проданных единиц товара по оплаченным заказам.';
COMMENT ON COLUMN analytics.sales_daily.gross_revenue IS 'Валовая выручка по оплаченным заказам за дату.';

CREATE VIEW analytics.order_funnel AS
SELECT
    o.status,
    COUNT(*)::bigint AS orders_count,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM orders), 0), 2) AS share_pct
FROM orders o
GROUP BY o.status;

COMMENT ON VIEW analytics.order_funnel IS '[DAMA-DMBOK: Analytical Data] Воронка заказов по текущим статусам с долями.';
COMMENT ON COLUMN analytics.order_funnel.status IS 'Статус заказа.';
COMMENT ON COLUMN analytics.order_funnel.orders_count IS 'Количество заказов в статусе.';
COMMENT ON COLUMN analytics.order_funnel.share_pct IS 'Доля заказов в статусе от общего числа заказов, %.';

CREATE VIEW analytics.top_products_30d AS
SELECT
    p.sku,
    p.name,
    c.name AS category_name,
    SUM(oi.quantity)::bigint AS units_sold,
    SUM(oi.quantity * oi.price)::NUMERIC(14,2) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.sku = oi.product_id
LEFT JOIN categories c ON c.id = p.category_id
WHERE o.is_paid = TRUE
  AND o.created_at >= NOW() - INTERVAL '30 days'
GROUP BY p.sku, p.name, c.name
ORDER BY revenue DESC, units_sold DESC;

COMMENT ON VIEW analytics.top_products_30d IS '[DAMA-DMBOK: Analytical Data] Топ товаров за последние 30 дней по выручке и количеству.';
COMMENT ON COLUMN analytics.top_products_30d.sku IS 'Артикул товара.';
COMMENT ON COLUMN analytics.top_products_30d.name IS 'Название товара.';
COMMENT ON COLUMN analytics.top_products_30d.category_name IS 'Название категории товара.';
COMMENT ON COLUMN analytics.top_products_30d.units_sold IS 'Проданное количество за период.';
COMMENT ON COLUMN analytics.top_products_30d.revenue IS 'Выручка по товару за период.';

CREATE MATERIALIZED VIEW analytics.customer_rfm_snapshot AS
SELECT
    o.customer_id,
    MAX(o.created_at)::date AS last_order_date,
    (CURRENT_DATE - MAX(o.created_at)::date) AS recency_days,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.is_paid) AS frequency_paid_orders,
    COALESCE(SUM(CASE WHEN o.is_paid THEN oi.quantity * oi.price ELSE 0 END), 0)::NUMERIC(14,2) AS monetary_total
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.customer_id;

CREATE UNIQUE INDEX idx_customer_rfm_snapshot_customer
    ON analytics.customer_rfm_snapshot(customer_id);

COMMENT ON MATERIALIZED VIEW analytics.customer_rfm_snapshot IS '[DAMA-DMBOK: Analytical Data] Срез RFM-показателей по клиентам (Recency, Frequency, Monetary).';
COMMENT ON COLUMN analytics.customer_rfm_snapshot.customer_id IS 'Идентификатор клиента.';
COMMENT ON COLUMN analytics.customer_rfm_snapshot.last_order_date IS 'Дата последнего заказа клиента.';
COMMENT ON COLUMN analytics.customer_rfm_snapshot.recency_days IS 'Давность последнего заказа в днях.';
COMMENT ON COLUMN analytics.customer_rfm_snapshot.frequency_paid_orders IS 'Количество оплаченных заказов клиента.';
COMMENT ON COLUMN analytics.customer_rfm_snapshot.monetary_total IS 'Суммарная выручка по клиенту (только оплаченные заказы).';

-- ============================================================
-- Metadata bootstrap (data dictionary + quality rules)
-- ============================================================

INSERT INTO metadata_data_assets (
    schema_name, object_name, object_type, dama_type,
    business_owner, data_steward, description, refresh_frequency, contains_pii
) VALUES
    ('public', 'customers', 'table', 'Master Data', 'CRM Team', 'Data Office', 'Профили покупателей', 'real-time', TRUE),
    ('public', 'addresses', 'table', 'Master Data', 'CRM Team', 'Data Office', 'Адреса доставки покупателей', 'real-time', TRUE),
    ('public', 'categories', 'table', 'Reference', 'Catalog Team', 'Data Office', 'Категории товаров', 'on-demand', FALSE),
    ('public', 'products', 'table', 'Master Data', 'Catalog Team', 'Data Office', 'Карточки товаров', 'real-time', FALSE),
    ('public', 'warehouses', 'table', 'Master Data', 'Operations Team', 'Data Office', 'Справочник складов', 'on-demand', FALSE),
    ('public', 'inventory', 'table', 'Transactional', 'Operations Team', 'Data Office', 'Остатки по складам', 'real-time', FALSE),
    ('public', 'carts', 'table', 'Transactional', 'Ecom Team', 'Data Office', 'Корзины пользователей', 'real-time', FALSE),
    ('public', 'cart_items', 'table', 'Transactional', 'Ecom Team', 'Data Office', 'Позиции корзин', 'real-time', FALSE),
    ('public', 'orders', 'table', 'Transactional', 'Ecom Team', 'Data Office', 'Заказы клиентов', 'real-time', TRUE),
    ('public', 'order_items', 'table', 'Transactional', 'Ecom Team', 'Data Office', 'Позиции заказов', 'real-time', FALSE),
    ('public', 'payments', 'table', 'Transactional', 'Finance Team', 'Data Office', 'Платежи по заказам', 'real-time', FALSE),
    ('public', 'order_status_history', 'table', 'Transactional', 'Ecom Team', 'Data Office', 'История статусов заказов', 'real-time', FALSE),
    ('public', 'promotions', 'table', 'Reference', 'Marketing Team', 'Data Office', 'Акции и промокоды', 'daily', FALSE),
    ('public', 'promotion_products', 'table', 'Reference', 'Marketing Team', 'Data Office', 'Привязка акций к товарам', 'daily', FALSE),
    ('public', 'support_tickets', 'table', 'Transactional', 'Support Team', 'Data Office', 'Обращения в поддержку', 'real-time', TRUE),
    ('public', 'customer_segments', 'table', 'Reference', 'CRM Team', 'Data Office', 'Справочник сегментов', 'daily', FALSE),
    ('public', 'customer_segment_members', 'table', 'Reference', 'CRM Team', 'Data Office', 'Состав сегментов клиентов', 'daily', FALSE),
    ('public', 'metadata_data_assets', 'table', 'Metadata', 'Data Office', 'Data Office', 'Реестр объектов данных', 'daily', FALSE),
    ('public', 'metadata_data_elements', 'table', 'Metadata', 'Data Office', 'Data Office', 'Словарь атрибутов данных', 'daily', FALSE),
    ('public', 'metadata_data_quality_rules', 'table', 'Metadata', 'Data Office', 'Data Office', 'Правила качества данных', 'daily', FALSE),
    ('analytics', 'sales_daily', 'view', 'Analytical', 'BI Team', 'Data Office', 'Дневная витрина продаж', 'daily', FALSE),
    ('analytics', 'order_funnel', 'view', 'Analytical', 'BI Team', 'Data Office', 'Воронка статусов заказов', 'daily', FALSE),
    ('analytics', 'top_products_30d', 'view', 'Analytical', 'BI Team', 'Data Office', 'Топ товаров за 30 дней', 'daily', FALSE),
    ('analytics', 'customer_rfm_snapshot', 'materialized_view', 'Analytical', 'BI Team', 'Data Office', 'RFM-срез по клиентам', 'daily', FALSE)
ON CONFLICT (schema_name, object_name, object_type) DO UPDATE
SET
    dama_type = EXCLUDED.dama_type,
    business_owner = EXCLUDED.business_owner,
    data_steward = EXCLUDED.data_steward,
    description = EXCLUDED.description,
    refresh_frequency = EXCLUDED.refresh_frequency,
    contains_pii = EXCLUDED.contains_pii,
    updated_at = NOW();

WITH objects AS (
    SELECT table_schema AS schema_name, table_name AS object_name
    FROM information_schema.tables
    WHERE table_schema IN ('public', 'analytics')
    UNION
    SELECT schemaname AS schema_name, matviewname AS object_name
    FROM pg_matviews
    WHERE schemaname = 'analytics'
)
INSERT INTO metadata_data_elements (
    asset_id, column_name, logical_name, business_definition,
    source_system, is_nullable, pii_class, sample_format, dq_expectation
)
SELECT
    a.id AS asset_id,
    c.column_name,
    c.column_name AS logical_name,
    COALESCE(
        col_description(format('%I.%I', c.table_schema, c.table_name)::regclass, c.ordinal_position),
        'Автозагрузка из information_schema: требуется уточнение бизнес-определения.'
    ) AS business_definition,
    'postgresql' AS source_system,
    (c.is_nullable = 'YES') AS is_nullable,
    CASE
        WHEN c.column_name IN ('email', 'phone', 'ip', 'message') THEN 'high'
        WHEN c.column_name IN ('name', 'subject', 'city', 'street') THEN 'medium'
        ELSE 'none'
    END AS pii_class,
    c.data_type AS sample_format,
    CASE
        WHEN c.is_nullable = 'NO' THEN 'Должно быть заполнено всегда.'
        ELSE 'Допускается NULL в рамках текущей модели.'
    END AS dq_expectation
FROM information_schema.columns c
JOIN objects o
  ON o.schema_name = c.table_schema
 AND o.object_name = c.table_name
JOIN metadata_data_assets a
  ON a.schema_name = c.table_schema
 AND a.object_name = c.table_name
WHERE c.table_schema IN ('public', 'analytics')
ON CONFLICT (asset_id, column_name) DO UPDATE
SET
    business_definition = EXCLUDED.business_definition,
    is_nullable = EXCLUDED.is_nullable,
    pii_class = EXCLUDED.pii_class,
    sample_format = EXCLUDED.sample_format,
    dq_expectation = EXCLUDED.dq_expectation,
    updated_at = NOW();

INSERT INTO metadata_data_quality_rules (
    asset_id, column_name, rule_name, rule_type, rule_sql, severity, threshold_pct, is_active
)
SELECT id, 'email', 'Customers email must be unique', 'uniqueness',
       'SELECT email FROM customers GROUP BY email HAVING COUNT(*) > 1', 'critical', 0.00, TRUE
FROM metadata_data_assets
WHERE schema_name = 'public' AND object_name = 'customers' AND object_type = 'table'
UNION ALL
SELECT id, 'status', 'Orders status must be in business lifecycle', 'validity',
       'SELECT order_id FROM orders WHERE status NOT IN (''created'',''paid'',''processing'',''shipped'',''delivered'',''cancelled'')', 'critical', 0.00, TRUE
FROM metadata_data_assets
WHERE schema_name = 'public' AND object_name = 'orders' AND object_type = 'table'
UNION ALL
SELECT id, 'quantity', 'Order item quantity must be positive', 'validity',
       'SELECT id FROM order_items WHERE quantity <= 0', 'critical', 0.00, TRUE
FROM metadata_data_assets
WHERE schema_name = 'public' AND object_name = 'order_items' AND object_type = 'table'
UNION ALL
SELECT id, 'paid_orders', 'Paid orders should not exceed total orders', 'consistency',
       'SELECT order_date FROM analytics.sales_daily WHERE paid_orders > orders_total', 'warning', 0.00, TRUE
FROM metadata_data_assets
WHERE schema_name = 'analytics' AND object_name = 'sales_daily' AND object_type = 'view';

-- ============================================================
-- Technical DB users (read-only + admin)
-- ============================================================
-- Замените пароли перед продакшен-деплоем.
-- Пароли задаются отдельным init-скриптом db/init-users.sh из переменных окружения.
-- Рекомендация: хранить реальные секреты вне репозитория (env / secret manager).

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ecom_tech_ro') THEN
        CREATE ROLE ecom_tech_ro LOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ecom_tech_admin') THEN
        CREATE ROLE ecom_tech_admin LOGIN;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE ecommerce TO ecom_tech_ro;
GRANT CONNECT ON DATABASE ecommerce TO ecom_tech_admin;

GRANT USAGE ON SCHEMA public TO ecom_tech_ro;
GRANT USAGE ON SCHEMA analytics TO ecom_tech_ro;

GRANT USAGE, CREATE ON SCHEMA public TO ecom_tech_admin;
GRANT USAGE, CREATE ON SCHEMA analytics TO ecom_tech_admin;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO ecom_tech_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO ecom_tech_ro;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO ecom_tech_ro;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA analytics TO ecom_tech_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA public
    GRANT SELECT ON TABLES TO ecom_tech_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA analytics
    GRANT SELECT ON TABLES TO ecom_tech_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA public
    GRANT SELECT ON SEQUENCES TO ecom_tech_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA analytics
    GRANT SELECT ON SEQUENCES TO ecom_tech_ro;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ecom_tech_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analytics TO ecom_tech_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ecom_tech_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA analytics TO ecom_tech_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ecom_tech_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA analytics TO ecom_tech_admin;

ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA public
    GRANT ALL PRIVILEGES ON TABLES TO ecom_tech_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA analytics
    GRANT ALL PRIVILEGES ON TABLES TO ecom_tech_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA public
    GRANT ALL PRIVILEGES ON SEQUENCES TO ecom_tech_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA analytics
    GRANT ALL PRIVILEGES ON SEQUENCES TO ecom_tech_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA public
    GRANT ALL PRIVILEGES ON FUNCTIONS TO ecom_tech_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE ecommerce IN SCHEMA analytics
    GRANT ALL PRIVILEGES ON FUNCTIONS TO ecom_tech_admin;
