# C2: Как могла бы выглядеть монолитная архитектура

Учебный пример того, как это же e-commerce решение может быть реализовано как **классический монолит**: один основной backend-процесс, одна база данных и единый релиз.

## Идея классического монолита

- Один исполняемый сервис `E-commerce Monolith App`.
- Один артефакт сборки и один деплой для всей бизнес-логики.
- Одна общая БД (`Monolith DB`) для всех доменов.
- Интеграции с внешними системами выполняются из монолита.

## C4-PlantUML (Container / C2)

```plantuml
@startuml
skinparam linetype ortho
skinparam nodesep 80
skinparam ranksep 80
!includeurl https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title C2 (Monolith): E-commerce как классический монолит
LAYOUT_LEFT_RIGHT()
AddRelTag("sync_call", $lineColor="blue", $textColor="blue")
AddRelTag("integration_flow", $lineColor="darkgreen", $textColor="darkgreen")

Person(Customer, "Покупатель", "Оформляет и отслеживает заказ")
System_Ext(WebClient, "Web/Mobile Client", "Пользовательский клиент")
System_Ext(ERP, "ERP/WMS", "Внешние back-office системы")
System_Ext(PaymentProvider, "Payment Provider", "Внешний платежный провайдер")
System_Ext(SmsEmailProvider, "SMS/Email Provider", "Внешний уведомительный провайдер")

System_Boundary(ECOM_MONO, "E-commerce Platform (Monolith)") {
  Container(MonolithApp, "E-commerce Monolith App", "Python/FastAPI", "Единое приложение: API, доменная логика, интеграции")

  ContainerDb(MonolithDb, "Monolith DB", "PostgreSQL", "Общая БД (orders, payments, inventory, shipping, customers)")

  Lay_D(MonolithDb, MonolithApp)
}

Rel(Customer, WebClient, "Использует UI", "Browser/App")
Rel(WebClient, MonolithApp, "Оформляет заказ / запрашивает статус", "HTTPS/JSON", $tags="sync_call")
Rel(MonolithApp, MonolithDb, "CRUD по всем доменам", "SQL")
Rel(MonolithApp, ERP, "Интеграция заказов/стоков", "SOAP/AMQP", $tags="integration_flow")
Rel(MonolithApp, PaymentProvider, "Проведение платежа", "HTTPS", $tags="integration_flow")
Rel(MonolithApp, SmsEmailProvider, "Отправка уведомлений", "HTTPS", $tags="integration_flow")

note right of MonolithApp
Классический монолит:
- один процесс приложения
- одна кодовая база и один релиз
- одна общая БД
- интеграции выполняются из этого же приложения
end note

@enduml
```

## Когда монолит уместен

- Команда небольшая, нужен быстрый time-to-market.
- Домены сильно связаны и часто меняются вместе.
- Важна простая эксплуатация и единый pipeline релиза.

## Ограничения монолита

- Сложнее масштабировать отдельные домены независимо.
- Риск роста связанности между модулями.
- Со временем может расти время сборки/деплоя и сложность релизов.
