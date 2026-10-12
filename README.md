# Загрузка транзакций в ClickHouse

## Запуск

Нужны Docker с Compose v2, около 4 ГБ памяти и свободные порты 8123, 9096. Все команды выполняются из корня репозитория:

```bash
docker compose --profile tools build
docker compose up -d --wait --wait-timeout 240
```

ClickHouse: `localhost:8123`. Kafka для внешних подключений: `localhost:9096`.

Таблицы создаются автоматически из `sql/01_tables.sql`.

## Использование

Для проверки без скачивания данных:

```bash
docker compose run --rm loader /data/demo.csv
docker compose run --rm export /data/demo.csv --output /results/demo_max_by_state.csv
```

Для полного датасета положите свой test.csv в папку `data`. Перед загрузкой сбросьте данные примера:

```bash
docker compose down -v
docker compose up -d --wait --wait-timeout 240
docker compose run --rm loader /data/test.csv
docker compose run --rm export /data/test.csv
```

В `results/max_by_state.csv` сохранен результат для полного test.csv: 262144 транзакции. Запрос `sql/02_max_by_state.sql` выбирает категорию наибольшей отдельной транзакции в каждом штате. При одинаковой сумме выбирается наибольший `cat_id` по алфавиту.

Выполнить запрос отдельно:

```bash
docker compose exec -T clickhouse clickhouse-client < sql/02_max_by_state.sql
docker compose logs --tail=30 clickhouse
docker compose ps
```

## Оптимизация

Исходная схема для сравнения находится в `sql/00_baseline.sql`: строки, Float64, `ORDER BY tuple()`. В рабочем DDL использованы `DateTime`, `UInt32`, `Decimal`, `LowCardinality`, кодеки ZSTD, Delta и Gorilla. Данные разбиты по месяцам и отсортированы по `(us_state, transaction_time)`.

Projection `max_by_state` хранит промежуточный `argMax` по штатам. Она обновляется при вставке, ClickHouse автоматически использует ее для того же запроса.

Сравнить на загруженных данных:

```bash
docker compose exec -T clickhouse clickhouse-client --multiquery < sql/00_baseline.sql
docker compose exec -T clickhouse clickhouse-client --multiquery < sql/03_compare.sql
```

Первый скрипт пересоздает содержимое только сравнительной таблицы.
Второй выводит время запросов, прочитанные строки, использованную projection и размер таблиц.

Локальный замер на полном test.csv, медиана 10 запусков (кеш запросов отключен):

| Схема                               | Время, мс | Прочитано строк | Размер таблицы, МБ |
| ----------------------------------- | --------: | --------------: | -----------------: |
| Исходная                            |         8 |          262144 |              17,77 |
| Новые типы и кодеки, без projection |        11 |          262144 |              12,62 |
| С projection                        |         6 |            1491 |              12,62 |

Числа сохранены в `results/benchmark.csv`. Размер рабочей таблицы включает projection. Хранение занимает на 30% меньше места. Типы и кодеки сами по себе не ускорили этот запрос, ускорение дала предварительная агрегация в projection.

## Остановка

```bash
docker compose down
```
