# Three-Tier Architecture Diagram

Документация по трехзвенной архитектуре сервиса.

## Назначение

Диаграмма разделяет систему на три слоя:
- Presentation Tier (Frontend);
- Application Tier (Backend + бизнес-логика);
- Data Tier (PostgreSQL).

## PlantUML

```plantuml
@startuml
title Трехзвенная архитектура (Three-tier)
skinparam componentStyle rectangle

node "Presentation Tier" as presentation {
  component "Frontend\nReact + Vite\n:3000" as FE
}

node "Application Tier" as app {
  component "Backend\nFastAPI\n:8000" as BE
  component "Business Logic\norders router,\nvalidation, rules" as BL
}

node "Data Tier" as data {
  database "PostgreSQL\nschema public + analytics\n:5433" as PG
}

FE --> BE : HTTP/REST (JSON)
BE --> BL : вызов use-cases
BL --> PG : SQL (SELECT/INSERT/UPDATE)

note right of FE
Слой представления:\nUI, формы, маршруты,\nвизуализация данных
end note

note right of app
Слой приложения:\nAPI + правила предметной области
end note

note right of data
Слой данных:\nхранение и целостность
end note

@enduml
```
