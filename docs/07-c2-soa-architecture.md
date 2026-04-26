# C2: Как могла бы выглядеть SOA-архитектура

Учебный пример того, как e-commerce система может быть организована в стиле **SOA (Service-Oriented Architecture)**.

## Идея SOA для этого проекта

- Есть набор бизнес-сервисов (`Order`, `Payment`, `Inventory`, `Shipping`, `Customer`).
- Входящий трафик идет через единый `API Gateway`.
- Межсервисная интеграция проходит через `ESB` (маршрутизация, трансформации, policy).
- Общие возможности выносятся в enterprise-сервисы (`Auth`, `Notification`).
- Допускается более централизованная интеграция и каноническая модель сообщений.

## C4-PlantUML (Container / C2)

```plantuml
@startuml
skinparam linetype ortho
skinparam nodesep 80
skinparam ranksep 80
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (SOA): E-commerce с централизованной интеграцией через ESB
LAYOUT_LEFT_RIGHT()
AddRelTag("sync_call", $lineColor="blue", $textColor="blue")
AddRelTag("esb_flow", $lineColor="darkgreen", $textColor="darkgreen")

Person(Customer, "Покупатель", "Оформляет и отслеживает заказ")
System_Ext(ERP, "ERP/WMS", "Внешние back-office системы")
System_Ext(PaymentProvider, "Payment Provider", "Внешний платежный провайдер")

System_Boundary(ECOM_SOA, "E-commerce Platform (SOA)") {
  Container(ApiGateway, "API Gateway", "REST API", "Единая входная точка и фасад")
  Container(ESB, "Enterprise Service Bus (ESB)", "Integration layer", "Routing, transformation, orchestration, policies")

  Container(OrderService, "Order Service", "SOAP/REST service", "Управление заказами")
  Container(PaymentService, "Payment Service", "SOAP/REST service", "Платежные операции")
  Container(InventoryService, "Inventory Service", "SOAP/REST service", "Остатки и резервы")
  Container(ShippingService, "Shipping Service", "SOAP/REST service", "Отгрузка и доставка")
  Container(CustomerService, "Customer Service", "SOAP/REST service", "Данные клиентов")

  Container(AuthService, "Auth Service", "Shared enterprise service", "Аутентификация и авторизация")
  Container(NotificationService, "Notification Service", "Shared enterprise service", "Email/SMS уведомления")

  ContainerDb(OrderDb, "Order DB", "PostgreSQL", "Данные заказов")
  ContainerDb(PaymentDb, "Payment DB", "PostgreSQL", "Данные платежей")
  ContainerDb(InventoryDb, "Inventory DB", "PostgreSQL", "Данные остатков")
  ContainerDb(ShippingDb, "Shipping DB", "PostgreSQL", "Данные доставки")
  ContainerDb(CustomerDb, "Customer DB", "PostgreSQL", "Данные клиентов")

  Lay_R(ESB, ApiGateway)
  Lay_L(OrderService, ESB)
  Lay_R(PaymentService, ESB)
  Lay_U(ShippingService, ESB)
  Lay_D(InventoryService, ESB)
  Lay_D(CustomerService, InventoryService)
  Lay_U(AuthService, PaymentService)
  Lay_D(NotificationService, PaymentService)

  Lay_L(OrderDb, OrderService)
  Lay_L(PaymentDb, PaymentService)
  Lay_L(InventoryDb, InventoryService)
  Lay_L(ShippingDb, ShippingService)
  Lay_L(CustomerDb, CustomerService)
}

Rel(Customer, ApiGateway, "Оформляет заказ / запрашивает статус", "HTTPS/JSON", $tags="sync_call")
Rel(ApiGateway, ESB, "Передает бизнес-запрос", "REST/SOAP", $tags="esb_flow")
Rel(ESB, AuthService, "Проверка токена / policy check", "REST", $tags="esb_flow")

Rel(ESB, OrderService, "Route: CreateOrder / GetOrder", "SOAP/REST", $tags="esb_flow")
Rel(ESB, PaymentService, "Route: Authorize/Capture", "SOAP/REST", $tags="esb_flow")
Rel(ESB, InventoryService, "Route: Reserve/Release", "SOAP/REST", $tags="esb_flow")
Rel(ESB, ShippingService, "Route: CreateShipment", "SOAP/REST", $tags="esb_flow")
Rel(ESB, CustomerService, "Route: GetCustomer", "SOAP/REST", $tags="esb_flow")

Rel(OrderService, OrderDb, "CRUD заказов", "SQL")
Rel(PaymentService, PaymentDb, "CRUD платежей", "SQL")
Rel(InventoryService, InventoryDb, "CRUD остатков", "SQL")
Rel(ShippingService, ShippingDb, "CRUD доставки", "SQL")
Rel(CustomerService, CustomerDb, "CRUD клиентов", "SQL")

Rel(ESB, PaymentProvider, "Интеграция платежей", "HTTPS", $tags="esb_flow")
Rel(ESB, ERP, "Интеграция заказов/стоков", "SOAP/AMQP", $tags="esb_flow")
Rel(ESB, NotificationService, "Команда на уведомление", "REST/Queue", $tags="esb_flow")

note right of ESB
SOA-подход:
- централизованный integration layer
- единые политики безопасности
- трансформация сообщений и каноническая модель
- прямые межсервисные вызовы исключены
end note

@enduml
```

## Когда SOA может быть уместна

- Есть много legacy/enterprise систем (ERP, CRM, WMS, billing).
- Нужна строгая централизация интеграций и governance.
- Важны единые integration-политики и повторное использование shared-сервисов.

## Ограничения SOA

- ESB может стать узким местом и точкой сложности.
- Изменения интеграционных контрактов требуют сильной дисциплины.
- Командам сложнее выпускать полностью независимые изменения, чем в microservices-first подходе.
