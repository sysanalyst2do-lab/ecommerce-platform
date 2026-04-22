# C2 Kafka Integration Diagram

Упрощенная C2-диаграмма в нотации C4-PlantUML: платформа получает события по стокам от системы склада через Kafka Broker.

## Контекст

- Источник событий: `WMS` (система склада)
- Брокер сообщений: `Kafka Broker`
- Получатель: `Stock Events Consumer`
- Хранилище: `PostgreSQL (orders + inventory)`
- Чтение данных: `Orders API`

## PlantUML (C4)

```plantuml
@startuml
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (C4-PlantUML): Получение событий по стокам от системы склада
LAYOUT_LEFT_RIGHT()

System_Ext(WMS, "Система склада (WMS)", "Источник событий об остатках")
SystemQueue_Ext(KAFKA, "Kafka Broker", "Message broker / event bus")

System_Boundary(ECOM, "E-commerce Platform") {
  Container(STOCK_CONSUMER, "Stock Events Consumer", "Python worker", "Читает stock-события и обновляет остатки")
  Container(API, "Orders API", "FastAPI", "Возвращает остатки и использует их в бизнес-логике")
  ContainerDb(DB, "PostgreSQL", "orders + inventory", "Хранение заказов и текущих остатков")
}

Rel(WMS, KAFKA, "Публикует события", "topic: warehouse.stock-events.v1")
Rel(KAFKA, STOCK_CONSUMER, "Передает события", "consume")
Rel(STOCK_CONSUMER, DB, "Обновляет таблицу inventory", "UPSERT")
Rel(API, DB, "Читает остатки и заказы", "SQL")

note right of STOCK_CONSUMER
События (пример):
- StockReserved
- StockReleased
- StockAdjusted
end note

@enduml
```
