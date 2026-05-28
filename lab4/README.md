## Запуск

```bash
# 1. Запустить все контейнеры
docker compose up -d

# 2. Запустить ETL (создание модели "звезда")
docker exec lab4-trino trino --server localhost:8080 --file /scripts/trino_etl_dwh.sql

# 3. Запустить создание отчетов
docker exec lab4-trino trino --server localhost:8080 --file /scripts/trino_etl_reports.sql

# 4. Проверить результаты в ClickHouse
docker exec lab4-clickhouse clickhouse-client --user admin --password admin123 --query "SELECT COUNT(*) FROM dwh.fact_sales"