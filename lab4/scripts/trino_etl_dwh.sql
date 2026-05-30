CREATE SCHEMA IF NOT EXISTS clickhouse.dwh;


DROP TABLE IF EXISTS clickhouse.dwh.dim_customers;
CREATE TABLE clickhouse.dwh.dim_customers AS
WITH pg_data AS (
    SELECT 
        CAST(sale_customer_id AS VARCHAR) as customer_id,
        1 as source,
        CAST(customer_first_name AS VARCHAR) as customer_first_name,
        CAST(customer_last_name AS VARCHAR) as customer_last_name,
        CAST(customer_age AS VARCHAR) as customer_age,
        CAST(customer_email AS VARCHAR) as customer_email,
        CAST(customer_country AS VARCHAR) as customer_country,
        CAST(customer_postal_code AS VARCHAR) as customer_postal_code,
        CAST(customer_pet_type AS VARCHAR) as customer_pet_type,
        CAST(customer_pet_name AS VARCHAR) as customer_pet_name,
        CAST(customer_pet_breed AS VARCHAR) as customer_pet_breed
    FROM postgresql.public.mock_data
    WHERE sale_customer_id IS NOT NULL
),
ch_data AS (
    SELECT 
        CAST(sale_customer_id AS VARCHAR) as customer_id,
        2 as source,
        from_utf8(customer_first_name) as customer_first_name,
        from_utf8(customer_last_name) as customer_last_name,
        CAST(customer_age AS VARCHAR) as customer_age,
        from_utf8(customer_email) as customer_email,
        from_utf8(customer_country) as customer_country,
        from_utf8(customer_postal_code) as customer_postal_code,
        from_utf8(customer_pet_type) as customer_pet_type,
        from_utf8(customer_pet_name) as customer_pet_name,
        from_utf8(customer_pet_breed) as customer_pet_breed
    FROM clickhouse.default.mock_data
    WHERE sale_customer_id IS NOT NULL
),
unified_data AS (
    SELECT * FROM pg_data
    UNION ALL
    SELECT * FROM ch_data
)
SELECT 
    customer_id,
    source,
    customer_first_name,
    customer_last_name,
    CONCAT(customer_first_name, ' ', customer_last_name) as customer_full_name,
    customer_age,
    customer_email,
    customer_country,
    customer_postal_code,
    customer_pet_type,
    customer_pet_name,
    customer_pet_breed
FROM unified_data;

DROP TABLE IF EXISTS clickhouse.dwh.dim_sellers;
CREATE TABLE clickhouse.dwh.dim_sellers AS
WITH pg_data AS (
    SELECT 
        CAST(sale_seller_id AS VARCHAR) as seller_id,
        1 as source,
        CAST(seller_first_name AS VARCHAR) as seller_first_name,
        CAST(seller_last_name AS VARCHAR) as seller_last_name,
        CAST(seller_email AS VARCHAR) as seller_email,
        CAST(seller_country AS VARCHAR) as seller_country,
        CAST(seller_postal_code AS VARCHAR) as seller_postal_code
    FROM postgresql.public.mock_data
    WHERE sale_seller_id IS NOT NULL
),
ch_data AS (
    SELECT 
        CAST(sale_seller_id AS VARCHAR) as seller_id,
        2 as source,
        from_utf8(seller_first_name) as seller_first_name,
        from_utf8(seller_last_name) as seller_last_name,
        from_utf8(seller_email) as seller_email,
        from_utf8(seller_country) as seller_country,
        from_utf8(seller_postal_code) as seller_postal_code
    FROM clickhouse.default.mock_data
    WHERE sale_seller_id IS NOT NULL
),
unified_data AS (
    SELECT * FROM pg_data
    UNION ALL
    SELECT * FROM ch_data
)
SELECT 
    seller_id,
    source,
    seller_first_name,
    seller_last_name,
    CONCAT(seller_first_name, ' ', seller_last_name) as seller_full_name,
    seller_email,
    seller_country,
    seller_postal_code
FROM unified_data;

DROP TABLE IF EXISTS clickhouse.dwh.dim_products;
CREATE TABLE clickhouse.dwh.dim_products AS
WITH pg_data AS (
    SELECT 
        CAST(sale_product_id AS VARCHAR) as product_id,
        1 as source,
        CAST(product_name AS VARCHAR) as product_name,
        CAST(product_category AS VARCHAR) as product_category,
        CAST(product_price AS VARCHAR) as product_price,
        CAST(product_rating AS VARCHAR) as product_rating,
        CAST(product_reviews AS VARCHAR) as product_reviews,
        CAST(supplier_name AS VARCHAR) as supplier_name,
        CAST(supplier_country AS VARCHAR) as supplier_country
    FROM postgresql.public.mock_data
    WHERE sale_product_id IS NOT NULL
),
ch_data AS (
    SELECT 
        CAST(sale_product_id AS VARCHAR) as product_id,
        2 as source,
        from_utf8(product_name) as product_name,
        from_utf8(product_category) as product_category,
        CAST(product_price AS VARCHAR) as product_price,
        CAST(product_rating AS VARCHAR) as product_rating,
        CAST(product_reviews AS VARCHAR) as product_reviews,
        from_utf8(supplier_name) as supplier_name,
        from_utf8(supplier_country) as supplier_country
    FROM clickhouse.default.mock_data
    WHERE sale_product_id IS NOT NULL
),
unified_data AS (
    SELECT * FROM pg_data
    UNION ALL
    SELECT * FROM ch_data
)
SELECT 
    product_id,
    source,
    product_name,
    product_category,
    product_price,
    product_rating,
    product_reviews,
    supplier_name,
    supplier_country
FROM unified_data;

DROP TABLE IF EXISTS clickhouse.dwh.dim_stores;
CREATE TABLE clickhouse.dwh.dim_stores AS
WITH pg_stores AS (
    SELECT DISTINCT
        CAST(store_name AS VARCHAR) as store_name,
        CAST(store_city AS VARCHAR) as store_city,
        CAST(store_country AS VARCHAR) as store_country
    FROM postgresql.public.mock_data
    WHERE store_name IS NOT NULL
),
ch_stores AS (
    SELECT DISTINCT
        from_utf8(store_name) as store_name,
        from_utf8(store_city) as store_city,
        from_utf8(store_country) as store_country
    FROM clickhouse.default.mock_data
    WHERE store_name IS NOT NULL
),
all_stores AS (
    SELECT * FROM pg_stores
    UNION
    SELECT * FROM ch_stores
)
SELECT 
    ROW_NUMBER() OVER () as store_id,
    store_name,
    store_city,
    store_country
FROM all_stores;

DROP TABLE IF EXISTS clickhouse.dwh.dim_date;
CREATE TABLE clickhouse.dwh.dim_date AS
SELECT DISTINCT
    CAST(sale_date AS DATE) as date_id,
    EXTRACT(YEAR FROM CAST(sale_date AS DATE)) as year,
    EXTRACT(MONTH FROM CAST(sale_date AS DATE)) as month,
    EXTRACT(DAY FROM CAST(sale_date AS DATE)) as day,
    EXTRACT(QUARTER FROM CAST(sale_date AS DATE)) as quarter,
    CASE EXTRACT(DOW FROM CAST(sale_date AS DATE))
        WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday' WHEN 6 THEN 'Saturday'
        WHEN 0 THEN 'Sunday'
    END as day_of_week,
    CASE 
        WHEN EXTRACT(MONTH FROM CAST(sale_date AS DATE)) IN (12, 1, 2) THEN 'Winter'
        WHEN EXTRACT(MONTH FROM CAST(sale_date AS DATE)) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM CAST(sale_date AS DATE)) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM CAST(sale_date AS DATE)) IN (9, 10, 11) THEN 'Autumn'
    END as season
FROM (
    SELECT sale_date FROM postgresql.public.mock_data WHERE sale_date IS NOT NULL
    UNION
    SELECT sale_date FROM clickhouse.default.mock_data WHERE sale_date IS NOT NULL
);

DROP TABLE IF EXISTS clickhouse.dwh.fact_sales;
CREATE TABLE clickhouse.dwh.fact_sales AS
WITH all_sales AS (
    SELECT 
        CAST(sale_customer_id AS VARCHAR) as customer_id,
        1 as customer_source,
        CAST(sale_seller_id AS VARCHAR) as seller_id,
        1 as seller_source,
        CAST(sale_product_id AS VARCHAR) as product_id,
        1 as product_source,
        CAST(store_name AS VARCHAR) as store_name,
        CAST(store_city AS VARCHAR) as store_city,
        CAST(sale_date AS DATE) as date_id,
        CAST(sale_quantity AS INTEGER) as sale_quantity,
        CAST(sale_total_price AS DECIMAL(10,2)) as sale_total_price
    FROM postgresql.public.mock_data
    WHERE sale_customer_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        CAST(sale_customer_id AS VARCHAR) as customer_id,
        2 as customer_source,
        CAST(sale_seller_id AS VARCHAR) as seller_id,
        2 as seller_source,
        CAST(sale_product_id AS VARCHAR) as product_id,
        2 as product_source,
        from_utf8(store_name) as store_name,
        from_utf8(store_city) as store_city,
        CAST(sale_date AS DATE) as date_id,
        CAST(sale_quantity AS INTEGER) as sale_quantity,
        CAST(sale_total_price AS DECIMAL(10,2)) as sale_total_price
    FROM clickhouse.default.mock_data
    WHERE sale_customer_id IS NOT NULL
),
stores_fixed AS (
    SELECT 
        store_id,
        from_utf8(store_name) as store_name,
        from_utf8(store_city) as store_city,
        from_utf8(store_country) as store_country
    FROM clickhouse.dwh.dim_stores
)
SELECT 
    ROW_NUMBER() OVER () as sale_id,
    s.customer_id,
    s.customer_source,
    s.seller_id,
    s.seller_source,
    s.product_id,
    s.product_source,
    COALESCE(st.store_id, -1) as store_id,
    s.date_id,
    s.sale_quantity,
    s.sale_total_price
FROM all_sales s
LEFT JOIN stores_fixed st 
    ON s.store_name = st.store_name 
    AND s.store_city = st.store_city;

SELECT 'ETL COMPLETED!' as status;
SELECT 'dim_customers' as table_name, COUNT(*) as rows FROM clickhouse.dwh.dim_customers
UNION ALL SELECT 'dim_sellers', COUNT(*) FROM clickhouse.dwh.dim_sellers
UNION ALL SELECT 'dim_products', COUNT(*) FROM clickhouse.dwh.dim_products
UNION ALL SELECT 'dim_stores', COUNT(*) FROM clickhouse.dwh.dim_stores
UNION ALL SELECT 'dim_date', COUNT(*) FROM clickhouse.dwh.dim_date
UNION ALL SELECT 'fact_sales', COUNT(*) FROM clickhouse.dwh.fact_sales;