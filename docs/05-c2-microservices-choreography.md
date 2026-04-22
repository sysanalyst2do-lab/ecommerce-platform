# C2: Микросервисы в стиле хореографии

Учебный пример того, как ваше e-commerce приложение может выглядеть в модели **choreography**:
каждый сервис реагирует на события, нет единого центрального "дирижера".

## Идея

- `Order Service` публикует событие `OrderCreated`.
- `Payment Service` сам подписывается на событие и публикует `PaymentSucceeded`.
- `Inventory Service` подписывается на факт оплаты и резервирует сток.
- `Shipping Service` подписывается на факт резерва и создает отгрузку.
- Все взаимодействие между доменными сервисами идет через Kafka.

## C4-PlantUML (Container / C2)

```plantuml
@startuml
skinparam linetype ortho
skinparam nodesep 80
skinparam ranksep 80
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (Choreography): E-commerce на событиях Kafka
LAYOUT_LEFT_RIGHT()
AddRelTag("kafka", $lineColor="green", $textColor="green")

Person(Customer, "Покупатель", "Оформляет заказ")
SystemQueue_Ext(KAFKA, "Kafka Broker", "Message broker / event bus")

System_Boundary(ECOM, "E-commerce Platform") {
  Container(ApiGateway, "API Gateway", "REST API", "Входная точка для клиента")

  Container(OrderService, "Order Service", "Python/FastAPI", "Создает заказ и публикует OrderCreated")
  Container(PaymentService, "Payment Service", "Python worker", "Проводит оплату, публикует PaymentSucceeded")
  Container(InventoryService, "Inventory Service", "Python worker", "Резервирует сток, публикует StockReserved")
  Container(ShippingService, "Shipping Service", "Python worker", "Создает отгрузку, публикует ShipmentCreated")
  Container(NotificationService, "Notification Service", "Python worker", "Отправляет уведомления по событиям")

  ContainerDb(OrderDb, "Order DB", "PostgreSQL", "Заказы")
  ContainerDb(PaymentDb, "Payment DB", "PostgreSQL", "Платежи")
  ContainerDb(InventoryDb, "Inventory DB", "PostgreSQL", "Остатки и резервы")
  ContainerDb(ShippingDb, "Shipping DB", "PostgreSQL", "Отгрузки")

  Lay_L(OrderDb, OrderService)
  Lay_L(PaymentDb, PaymentService)
  Lay_L(InventoryDb, InventoryService)
  Lay_L(ShippingDb, ShippingService)
}

Rel(Customer, ApiGateway, "Оформляет заказ", "HTTPS/JSON")
Rel(ApiGateway, OrderService, "POST /orders", "REST")
Rel(OrderService, OrderDb, "Сохраняет заказ", "SQL")
Rel(OrderService, KAFKA, "Publish OrderCreated", "orders.events.v1", $tags="kafka")

Rel(KAFKA, PaymentService, "Consume OrderCreated", "orders.events.v1", $tags="kafka")
Rel(PaymentService, PaymentDb, "Сохраняет платеж", "SQL")
Rel(PaymentService, KAFKA, "Publish PaymentSucceeded", "payments.events.v1", $tags="kafka")

Rel(KAFKA, InventoryService, "Consume PaymentSucceeded", "payments.events.v1", $tags="kafka")
Rel(InventoryService, InventoryDb, "Резервирует сток", "SQL")
Rel(InventoryService, KAFKA, "Publish StockReserved", "inventory.events.v1", $tags="kafka")

Rel(KAFKA, ShippingService, "Consume StockReserved", "inventory.events.v1", $tags="kafka")
Rel(ShippingService, ShippingDb, "Создает отгрузку", "SQL")
Rel(ShippingService, KAFKA, "Publish ShipmentCreated", "shipping.events.v1", $tags="kafka")

Rel(KAFKA, NotificationService, "Consume бизнес-события", "multiple topics", $tags="kafka")

note right of KAFKA
Сервисы слабо связаны:
каждый знает только
свои входные/выходные события.
end note

@enduml
```

## Что важно в хореографии

- Нет единой точки координации, поэтому система проще масштабируется.
- Но сложнее отслеживать end-to-end флоу и компенсирующие действия.
- Нужны строгие контракты событий, идемпотентность и DLQ.
