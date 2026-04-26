# C2: Микросервисы в стиле оркестрации

Учебный пример того, как ваше e-commerce приложение может выглядеть в модели **orchestration**:
центральный сервис-оркестратор управляет шагами процесса.

## Идея

- `Order Orchestrator` принимает команду "создать заказ".
- Оркестратор последовательно вызывает/командует `Payment`, `Inventory`, `Shipping`.
- Сервисы отвечают синхронными ответами, а общий сценарий хранится в оркестраторе.
- Kafka используется только для внешних интеграционных событий.

## C4-PlantUML (Container / C2)

```plantuml
@startuml
skinparam nodesep 80
skinparam ranksep 80
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (Orchestration): E-commerce с центральным оркестратором
LAYOUT_LEFT_RIGHT()
AddRelTag("orch_cmd", $lineColor="green", $textColor="green")

Person(Customer, "Покупатель", "Оформляет заказ")
SystemQueue_Ext(KAFKA, "Kafka Broker", "Integration events transport")

System_Boundary(ECOM, "E-commerce Platform") {
  Container(ApiGateway, "API Gateway", "REST API", "Входная точка для клиента")
  Container(Orchestrator, "Order Orchestrator", "Saga/Workflow service", "Управляет шагами checkout-процесса")

  Container(OrderService, "Order Service", "Python/FastAPI", "Создает/обновляет заказ")
  Container(PaymentService, "Payment Service", "Python worker", "Платежи")
  Container(InventoryService, "Inventory Service", "Python worker", "Резерв стока")
  Container(ShippingService, "Shipping Service", "Python worker", "Создание отгрузки")

  ContainerDb(OrderDb, "Order DB", "PostgreSQL", "Заказы")
  ContainerDb(OrchDb, "Orchestrator DB", "PostgreSQL", "Состояния саг и шагов")
  ContainerDb(PaymentDb, "Payment DB", "PostgreSQL", "Платежи")
  ContainerDb(InventoryDb, "Inventory DB", "PostgreSQL", "Остатки и резервы")
  ContainerDb(ShippingDb, "Shipping DB", "PostgreSQL", "Отгрузки")

  Lay_L(OrderDb, OrderService)
  Lay_L(OrchDb, Orchestrator)
  Lay_L(PaymentDb, PaymentService)
  Lay_L(InventoryDb, InventoryService)
  Lay_L(ShippingDb, ShippingService)
  Lay_L(OrchDb, ApiGateway)
}

Rel(Customer, ApiGateway, "Оформляет заказ", "HTTPS/JSON")
Rel(ApiGateway, Orchestrator, "POST /checkout", "REST")

Rel(Orchestrator, OrderService, "CreateOrder", "HTTP/gRPC", $tags="orch_cmd")
Rel(OrderService, OrderDb, "Сохраняет заказ", "SQL")

Rel(Orchestrator, PaymentService, "AuthorizePayment", "HTTP/gRPC", $tags="orch_cmd")
Rel(PaymentService, Orchestrator, "Payment result", "HTTP/gRPC")
Rel(PaymentService, PaymentDb, "Сохраняет платеж", "SQL")

Rel(Orchestrator, InventoryService, "ReserveStock", "HTTP/gRPC", $tags="orch_cmd")
Rel(InventoryService, Orchestrator, "Stock result", "HTTP/gRPC")
Rel(InventoryService, InventoryDb, "Резервирует сток", "SQL")

Rel(Orchestrator, ShippingService, "CreateShipment", "HTTP/gRPC", $tags="orch_cmd")
Rel(ShippingService, Orchestrator, "Shipment result", "HTTP/gRPC")
Rel(ShippingService, ShippingDb, "Сохраняет отгрузку", "SQL")

Rel(Orchestrator, OrchDb, "Хранит состояние саги", "SQL")
Rel(Orchestrator, KAFKA, "Публикует интеграционные события", "integration.events.v1")

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
