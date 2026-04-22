# C2: Как могла бы выглядеть MSA-архитектура

Учебный пример того, как e-commerce система может быть реализована в стиле **MSA (Microservices Architecture)** по тем же базовым принципам: единая точка входа, явные bounded contexts, независимые сервисы и их хранилища.

## Идея классического MSA

- `API Gateway` как единая входная точка для клиента.
- Набор независимых сервисов по доменам: `Orders`, `Payments`, `Inventory`, `Shipping`, `Customers`.
- У каждого сервиса своя БД (`database-per-service`).
- Интеграция между сервисами: синхронно через API и/или асинхронно через брокер событий.

## C4-PlantUML (Container / C2)

```plantuml
@startuml
skinparam linetype ortho
skinparam nodesep 80
skinparam ranksep 80
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (MSA): E-commerce как набор микросервисов
LAYOUT_LEFT_RIGHT()
AddRelTag("sync_call", $lineColor="blue", $textColor="blue")
AddRelTag("event_flow", $lineColor="darkgreen", $textColor="darkgreen")

Person(Customer, "Покупатель", "Оформляет и отслеживает заказ")
System_Ext(WebClient, "Web/Mobile Client", "Пользовательский клиент")
SystemQueue_Ext(KAFKA, "Kafka Broker", "Событийная интеграция")

System_Boundary(ECOM_MSA, "E-commerce Platform (MSA)") {
  Container(ApiGateway, "API Gateway", "REST API", "Единая входная точка")

  Container(OrderService, "Order Service", "Python/FastAPI", "Заказы")
  Container(PaymentService, "Payment Service", "Python service", "Платежи")
  Container(InventoryService, "Inventory Service", "Python service", "Остатки и резервы")
  Container(ShippingService, "Shipping Service", "Python service", "Отгрузки")
  Container(CustomerService, "Customer Service", "Python service", "Клиенты")

  ContainerDb(OrderDb, "Order DB", "PostgreSQL", "Данные заказов")
  ContainerDb(PaymentDb, "Payment DB", "PostgreSQL", "Данные платежей")
  ContainerDb(InventoryDb, "Inventory DB", "PostgreSQL", "Данные остатков")
  ContainerDb(ShippingDb, "Shipping DB", "PostgreSQL", "Данные отгрузок")
  ContainerDb(CustomerDb, "Customer DB", "PostgreSQL", "Данные клиентов")

  Lay_R(OrderService, ApiGateway)
  Lay_R(PaymentService, OrderService)
  Lay_R(InventoryService, PaymentService)
  Lay_R(ShippingService, InventoryService)
  Lay_R(CustomerService, ShippingService)

  Lay_D(OrderDb, OrderService)
  Lay_D(PaymentDb, PaymentService)
  Lay_D(InventoryDb, InventoryService)
  Lay_D(ShippingDb, ShippingService)
  Lay_D(CustomerDb, CustomerService)
}

Rel(Customer, WebClient, "Использует UI", "Browser/App")
Rel(WebClient, ApiGateway, "Запросы клиента", "HTTPS/JSON", $tags="sync_call")

Rel(ApiGateway, OrderService, "Create/Get order", "REST", $tags="sync_call")
Rel(ApiGateway, CustomerService, "Get customer profile", "REST", $tags="sync_call")

Rel(OrderService, OrderDb, "CRUD заказов", "SQL")
Rel(PaymentService, PaymentDb, "CRUD платежей", "SQL")
Rel(InventoryService, InventoryDb, "CRUD остатков", "SQL")
Rel(ShippingService, ShippingDb, "CRUD отгрузок", "SQL")
Rel(CustomerService, CustomerDb, "CRUD клиентов", "SQL")

Rel(OrderService, KAFKA, "Publish OrderCreated", "orders.events.v1", $tags="event_flow")
Rel(KAFKA, PaymentService, "Consume OrderCreated", "orders.events.v1", $tags="event_flow")
Rel(PaymentService, KAFKA, "Publish PaymentSucceeded", "payments.events.v1", $tags="event_flow")
Rel(KAFKA, InventoryService, "Consume PaymentSucceeded", "payments.events.v1", $tags="event_flow")
Rel(InventoryService, KAFKA, "Publish StockReserved", "inventory.events.v1", $tags="event_flow")
Rel(KAFKA, ShippingService, "Consume StockReserved", "inventory.events.v1", $tags="event_flow")

note right of ApiGateway
Классический MSA:
- единая точка входа
- независимые сервисы
- отдельная БД у каждого сервиса
end note

@enduml
```

## Когда MSA уместна

- Несколько команд развивают разные домены независимо.
- Нужно независимое масштабирование отдельных частей системы.
- Важны частые автономные релизы сервисов.

## Ограничения MSA

- Выше инфраструктурная сложность (observability, network, security, CI/CD).
- Сложнее управление распределенными транзакциями и консистентностью.
- Требует зрелых практик контрактов API/событий и идемпотентности.
