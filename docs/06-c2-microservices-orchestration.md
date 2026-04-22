# C2: Микросервисы в стиле оркестрации

Учебный пример того, как ваше e-commerce приложение может выглядеть в модели **orchestration**:
центральный сервис-оркестратор управляет шагами процесса.

## Идея

- `Order Orchestrator` принимает команду "создать заказ".
- Оркестратор последовательно вызывает/командует `Payment`, `Inventory`, `Shipping`.
- Сервисы отвечают статусами и событиями, но общий сценарий хранится в оркестраторе.
- Kafka используется как транспорт команд/результатов и для интеграционных событий.

## C4-PlantUML (Container / C2)

```plantuml
@startuml
skinparam nodesep 80
skinparam ranksep 80
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (Orchestration): E-commerce с центральным оркестратором
LAYOUT_LEFT_RIGHT()

Person(Customer, "Покупатель", "Оформляет заказ")
SystemQueue_Ext(KAFKA, "Kafka Broker", "Commands/events transport")

System_Boundary(ECOM, "E-commerce Platform") {
  Container(ApiGateway, "API Gateway", "REST API", "Входная точка для клиента")
  Container(Orchestrator, "Order Orchestrator", "Saga/Workflow service", "Управляет шагами checkout-процесса")

  Container(OrderService, "Order Service", "Python/FastAPI", "Создает/обновляет заказ")
  Container(PaymentService, "Payment Service", "Python worker", "Платежи")
  Container(InventoryService, "Inventory Service", "Python worker", "Резерв стока")
  Container(ShippingService, "Shipping Service", "Python worker", "Создание отгрузки")

  ContainerDb(OrderDb, "Order DB", "PostgreSQL", "Заказы")
  ContainerDb(OrchDb, "Orchestrator DB", "PostgreSQL", "Состояния саг и шагов")

  Lay_L(OrderDb, OrderService)
  Lay_L(OrchDb, Orchestrator)
}

Rel(Customer, ApiGateway, "Оформляет заказ", "HTTPS/JSON")
Rel(ApiGateway, Orchestrator, "POST /checkout", "REST")

Rel(Orchestrator, OrderService, "CreateOrder command", "REST or Kafka command")
Rel(OrderService, OrderDb, "Сохраняет заказ", "SQL")
Rel(OrderService, KAFKA, "OrderCreated result", "orders.events.v1")
Rel(KAFKA, Orchestrator, "Consume result", "orders.events.v1")

Rel(Orchestrator, PaymentService, "AuthorizePayment command", "Kafka commands")
Rel(PaymentService, KAFKA, "PaymentSucceeded/Failed", "payments.events.v1")
Rel(KAFKA, Orchestrator, "Consume result", "payments.events.v1")

Rel(Orchestrator, InventoryService, "ReserveStock command", "Kafka commands")
Rel(InventoryService, KAFKA, "StockReserved/Failed", "inventory.events.v1")
Rel(KAFKA, Orchestrator, "Consume result", "inventory.events.v1")

Rel(Orchestrator, ShippingService, "CreateShipment command", "Kafka commands")
Rel(ShippingService, KAFKA, "ShipmentCreated/Failed", "shipping.events.v1")
Rel(KAFKA, Orchestrator, "Consume result", "shipping.events.v1")

Rel(Orchestrator, OrchDb, "Хранит состояние саги", "SQL")
Rel(Orchestrator, KAFKA, "Публикует compensating commands при ошибках", "commands topics")

note right of Orchestrator
Единая точка управления процессом:
- проще наблюдаемость
- явные таймауты/ретраи
- централизованные компенсации
end note

@enduml
```

## Что важно в оркестрации

- Проще контролировать сложные бизнес-процессы (Saga).
- Быстрее отлаживать "кто на каком шаге сломался".
- Но оркестратор становится критическим компонентом и точкой сложности.
