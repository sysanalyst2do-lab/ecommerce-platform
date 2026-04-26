# Allure отчеты по тестам

Этот документ объясняет, как запускать backend-тесты с Allure и смотреть отчет локально.

## Что уже добавлено в проект

- В `backend/requirements.txt` добавлен `allure-pytest`.
- В `ci.yml` backend-тесты запускаются с флагом `--alluredir=allure-results`.
- В CI выгружается артефакт `backend-allure-results`.

## Локальный запуск тестов с генерацией Allure результатов

Из корня репозитория:

```bash
cd backend
python -m pip install -r requirements.txt
python -m pytest tests -q --alluredir=allure-results
```

После выполнения появится папка `backend/allure-results`.

## Как посмотреть HTML отчет локально

### Вариант A: установлен Allure CLI

```bash
cd backend
allure serve allure-results
```

Команда поднимет локальный сервер и откроет отчет в браузере.

### Вариант B: через Docker (без локальной установки Allure)

```bash
docker run --rm -p 5050:5050 \
  -v "${PWD}/backend/allure-results:/allure-results" \
  frankescobar/allure-docker-service
```

Затем открыть:

- `http://localhost:5050/allure-docker-service/latest-report`

## Полезные команды

Запустить тесты и сразу обновить результаты:

```bash
cd backend
python -m pytest tests -q --alluredir=allure-results --clean-alluredir
```

Сгенерировать статический отчет в папку:

```bash
cd backend
allure generate allure-results --clean -o allure-report
```

## Что видно в отчете Allure

- список passed/failed тестов;
- длительность тестов;
- шаги и вложения (если добавить в тесты);
- общая статистика по прогонам.
