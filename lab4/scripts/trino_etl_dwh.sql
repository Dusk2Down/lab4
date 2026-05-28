
CREATE SCHEMA IF NOT EXISTS clickhouse.dwh;


DROP TABLE IF EXISTS clickhouse.dwh.dim_customers;
CREATE TABLE clickhouse.dwh.dim_customers AS
SELECT DISTINCT
    CAST(sale_customer_id AS BIGINT) as customer_id,
    CAST(customer_first_name AS VARCHAR) as customer_first_name,
    CAST(customer_last_name AS VARCHAR) as customer_last_name,
    customer_first_name || ' ' || customer_last_name as customer_full_name,
    CAST(customer_age AS INTEGER) as customer_age,
    CAST(customer_email AS VARCHAR) as customer_email,
    CAST(customer_country AS VARCHAR) as customer_country,
    CAST(customer_postal_code AS VARCHAR) as customer_postal_code,
    CAST(customer_pet_type AS VARCHAR) as customer_pet_type,
    CAST(customer_pet_name AS VARCHAR) as customer_pet_name,
    CAST(customer_pet_breed AS VARCHAR) as customer_pet_breed
FROM postgresql.public.mock_data
WHERE sale_customer_id IS NOT NULL;


DROP TABLE IF EXISTS clickhouse.dwh.dim_sellers;
CREATE TABLE clickhouse.dwh.dim_sellers AS
SELECT DISTINCT
    CAST(sale_seller_id AS BIGINT) as seller_id,
    CAST(seller_first_name AS VARCHAR) as seller_first_name,
    CAST(seller_last_name AS VARCHAR) as seller_last_name,
    seller_first_name || ' ' || seller_last_name as seller_full_name,
    CAST(seller_email AS VARCHAR) as seller_email,
    CAST(seller_country AS VARCHAR) as seller_country,
    CAST(seller_postal_code AS VARCHAR) as seller_postal_code
FROM postgresql.public.mock_data
WHERE sale_seller_id IS NOT NULL;

DROP TABLE IF EXISTS clickhouse.dwh.dim_products;
CREATE TABLE clickhouse.dwh.dim_products AS
SELECT 
    product_id,
    ANY_VALUE(product_name) as product_name,
    ANY_VALUE(product_category) as product_category,
    ANY_VALUE(product_price) as product_price,
    ANY_VALUE(product_weight) as product_weight,
    ANY_VALUE(product_color) as product_color,
    ANY_VALUE(product_size) as product_size,
    ANY_VALUE(product_brand) as product_brand,
    ANY_VALUE(product_material) as product_material,
    ANY_VALUE(product_description) as product_description,
    ANY_VALUE(product_rating) as product_rating,
    ANY_VALUE(product_reviews) as product_reviews,
    ANY_VALUE(product_release_date) as product_release_date,
    ANY_VALUE(product_expiry_date) as product_expiry_date,
    ANY_VALUE(pet_category) as pet_category,
    ANY_VALUE(supplier_name) as supplier_name,
    ANY_VALUE(supplier_contact) as supplier_contact,
    ANY_VALUE(supplier_email) as supplier_email,
    ANY_VALUE(supplier_phone) as supplier_phone,
    ANY_VALUE(supplier_address) as supplier_address,
    ANY_VALUE(supplier_city) as supplier_city,
    ANY_VALUE(supplier_country) as supplier_country
FROM (
    SELECT DISTINCT
        CAST(sale_product_id AS BIGINT) as product_id,
        CAST(product_name AS VARCHAR) as product_name,
        CAST(product_category AS VARCHAR) as product_category,
        CAST(product_price AS DOUBLE) as product_price,
        CAST(product_weight AS DOUBLE) as product_weight,
        CAST(product_color AS VARCHAR) as product_color,
        CAST(product_size AS VARCHAR) as product_size,
        CAST(product_brand AS VARCHAR) as product_brand,
        CAST(product_material AS VARCHAR) as product_material,
        CAST(product_description AS VARCHAR) as product_description,
        CAST(product_rating AS DOUBLE) as product_rating,
        CAST(product_reviews AS INTEGER) as product_reviews,
        CAST(product_release_date AS DATE) as product_release_date,
        CAST(product_expiry_date AS DATE) as product_expiry_date,
        CAST(pet_category AS VARCHAR) as pet_category,
        CAST(supplier_name AS VARCHAR) as supplier_name,
        CAST(supplier_contact AS VARCHAR) as supplier_contact,
        CAST(supplier_email AS VARCHAR) as supplier_email,
        CAST(supplier_phone AS VARCHAR) as supplier_phone,
        CAST(supplier_address AS VARCHAR) as supplier_address,
        CAST(supplier_city AS VARCHAR) as supplier_city,
        CAST(supplier_country AS VARCHAR) as supplier_country
    FROM postgresql.public.mock_data
    WHERE sale_product_id IS NOT NULL
)
GROUP BY product_id;


DROP TABLE IF EXISTS clickhouse.dwh.dim_stores;
CREATE TABLE clickhouse.dwh.dim_stores AS
SELECT DISTINCT
    ROW_NUMBER() OVER () as store_id,
    CAST(store_name AS VARCHAR) as store_name,
    CAST(store_location AS VARCHAR) as store_location,
    CAST(store_city AS VARCHAR) as store_city,
    CAST(store_state AS VARCHAR) as store_state,
    CAST(store_country AS VARCHAR) as store_country,
    CAST(store_phone AS VARCHAR) as store_phone,
    CAST(store_email AS VARCHAR) as store_email
FROM postgresql.public.mock_data
WHERE store_name IS NOT NULL;


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
FROM postgresql.public.mock_data
WHERE sale_date IS NOT NULL;


DROP TABLE IF EXISTS clickhouse.dwh.fact_sales;
CREATE TABLE clickhouse.dwh.fact_sales AS
WITH stores AS (
    SELECT DISTINCT
        ROW_NUMBER() OVER () as store_id,
        CAST(store_name AS VARCHAR) as store_name,
        CAST(store_city AS VARCHAR) as store_city
    FROM postgresql.public.mock_data
    WHERE store_name IS NOT NULL
),
sales AS (
    SELECT DISTINCT
        CAST(sale_customer_id AS BIGINT) as customer_id,
        CAST(sale_seller_id AS BIGINT) as seller_id,
        CAST(sale_product_id AS BIGINT) as product_id,
        CAST(sale_date AS DATE) as date_id,
        CAST(sale_quantity AS INTEGER) as sale_quantity,
        CAST(sale_total_price AS DOUBLE) as sale_total_price,
        CAST(store_name AS VARCHAR) as store_name,
        CAST(store_city AS VARCHAR) as store_city
    FROM postgresql.public.mock_data
)
SELECT
    ROW_NUMBER() OVER () as sale_id,
    s.customer_id, s.seller_id, s.product_id,
    COALESCE(st.store_id, 0) as store_id,
    s.date_id, s.sale_quantity, s.sale_total_price,
    CASE WHEN s.sale_quantity > 0 THEN s.sale_total_price / s.sale_quantity ELSE 0 END as avg_price_per_unit
FROM sales s
LEFT JOIN stores st ON s.store_name = st.store_name AND s.store_city = st.store_city;

SELECT 'ETL SUCCESS!' as status;
SELECT 'dim_customers' as tbl, COUNT(*) as rows FROM clickhouse.dwh.dim_customers
UNION ALL SELECT 'dim_products', COUNT(*) FROM clickhouse.dwh.dim_products
UNION ALL SELECT 'dim_sellers', COUNT(*) FROM clickhouse.dwh.dim_sellers
UNION ALL SELECT 'dim_stores', COUNT(*) FROM clickhouse.dwh.dim_stores
UNION ALL SELECT 'dim_date', COUNT(*) FROM clickhouse.dwh.dim_date
UNION ALL SELECT 'fact_sales', COUNT(*) FROM clickhouse.dwh.fact_sales;
