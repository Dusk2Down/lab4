DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_10_products;

CREATE TABLE clickhouse.dwh.rpt_top_10_products AS
SELECT
    p.product_id,
    from_utf8(p.product_name) AS product_name,
    from_utf8(p.product_category) AS product_category,
    SUM(f.sale_quantity) AS total_quantity_sold,
    SUM(f.sale_total_price) AS total_revenue,
    AVG(CAST(from_utf8(p.product_rating) AS DOUBLE)) AS avg_rating
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_products p
    ON f.product_id = p.product_id
    AND f.product_source = p.source
GROUP BY
    p.product_id,
    p.product_name,
    p.product_category
ORDER BY total_quantity_sold DESC
LIMIT 10;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_revenue_by_category;

CREATE TABLE clickhouse.dwh.rpt_revenue_by_category AS
SELECT
    from_utf8(p.product_category) AS product_category,
    COUNT(DISTINCT p.product_id) AS product_count,
    SUM(f.sale_quantity) AS total_quantity_sold,
    SUM(f.sale_total_price) AS total_revenue,
    AVG(f.sale_total_price) AS avg_revenue_per_sale
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_products p
    ON f.product_id = p.product_id
    AND f.product_source = p.source
GROUP BY p.product_category
ORDER BY total_revenue DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_product_ratings;

CREATE TABLE clickhouse.dwh.rpt_product_ratings AS
SELECT
    p.product_id,
    from_utf8(p.product_name) AS product_name,
    from_utf8(p.product_category) AS product_category,
    CAST(from_utf8(p.product_rating) AS DOUBLE) AS product_rating,
    CAST(from_utf8(p.product_reviews) AS INTEGER) AS product_reviews,
    SUM(COALESCE(f.sale_quantity,0)) AS total_sold,
    SUM(COALESCE(f.sale_total_price,0)) AS total_revenue
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f
    ON p.product_id = f.product_id
    AND p.source = f.product_source
GROUP BY
    p.product_id,
    p.product_name,
    p.product_category,
    p.product_rating,
    p.product_reviews
ORDER BY product_rating DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_10_customers;

CREATE TABLE clickhouse.dwh.rpt_top_10_customers AS
SELECT
    c.customer_id,
    from_utf8(c.customer_full_name) AS customer_name,
    from_utf8(c.customer_country) AS customer_country,
    SUM(f.sale_total_price) AS total_spent,
    COUNT(*) AS total_orders,
    AVG(f.sale_total_price) AS avg_check
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_customers c
    ON f.customer_id = c.customer_id
    AND f.customer_source = c.source
GROUP BY
    c.customer_id,
    c.customer_full_name,
    c.customer_country
ORDER BY total_spent DESC
LIMIT 10;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_customers_by_country;

CREATE TABLE clickhouse.dwh.rpt_customers_by_country AS
SELECT
    from_utf8(c.customer_country) AS customer_country,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(f.sale_total_price) AS total_revenue,
    AVG(f.sale_total_price) AS avg_check
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_customers c
    ON f.customer_id = c.customer_id
    AND f.customer_source = c.source
GROUP BY c.customer_country
ORDER BY total_revenue DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_customer_avg_check;

CREATE TABLE clickhouse.dwh.rpt_customer_avg_check AS
SELECT
    c.customer_id,
    from_utf8(c.customer_full_name) AS customer_name,
    from_utf8(c.customer_country) AS customer_country,
    AVG(f.sale_total_price) AS avg_check,
    COUNT(*) AS order_count,
    SUM(f.sale_total_price) AS total_spent
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_customers c
    ON f.customer_id = c.customer_id
    AND f.customer_source = c.source
GROUP BY
    c.customer_id,
    c.customer_full_name,
    c.customer_country
ORDER BY avg_check DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_sales_trends;

CREATE TABLE clickhouse.dwh.rpt_sales_trends AS
SELECT
    EXTRACT(YEAR FROM f.date_id) AS year,
    EXTRACT(MONTH FROM f.date_id) AS month,
    COUNT(*) AS order_count,
    SUM(f.sale_quantity) AS total_quantity,
    SUM(f.sale_total_price) AS total_revenue,
    AVG(f.sale_total_price) AS avg_order_value
FROM clickhouse.dwh.fact_sales f
GROUP BY
    EXTRACT(YEAR FROM f.date_id),
    EXTRACT(MONTH FROM f.date_id)
ORDER BY year, month;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_period_comparison;

CREATE TABLE clickhouse.dwh.rpt_period_comparison AS
SELECT
    year,
    month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY year, month))
        / NULLIF(LAG(total_revenue) OVER (ORDER BY year, month),0)
        *100,
        2
    ) AS growth_percent
FROM clickhouse.dwh.rpt_sales_trends;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_avg_order_size;

CREATE TABLE clickhouse.dwh.rpt_avg_order_size AS
SELECT
    year,
    month,
    avg_order_value,
    order_count,
    total_revenue
FROM clickhouse.dwh.rpt_sales_trends
ORDER BY year, month;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_5_stores;

CREATE TABLE clickhouse.dwh.rpt_top_5_stores AS
SELECT
    from_utf8(s.store_name) AS store_name,
    from_utf8(s.store_city) AS store_city,
    from_utf8(s.store_country) AS store_country,
    COUNT(*) AS total_orders,
    SUM(f.sale_total_price) AS total_revenue,
    AVG(f.sale_total_price) AS avg_check
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_stores s
    ON f.store_id = s.store_id
WHERE f.store_id != -1
GROUP BY
    s.store_name,
    s.store_city,
    s.store_country
ORDER BY total_revenue DESC
LIMIT 5;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_sales_by_location;

CREATE TABLE clickhouse.dwh.rpt_sales_by_location AS
SELECT
    from_utf8(s.store_country) AS store_country,
    from_utf8(s.store_city) AS store_city,
    COUNT(DISTINCT f.store_id) AS store_count,
    SUM(f.sale_total_price) AS total_revenue,
    AVG(f.sale_total_price) AS avg_check
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_stores s
    ON f.store_id = s.store_id
WHERE f.store_id != -1
GROUP BY
    s.store_country,
    s.store_city
ORDER BY total_revenue DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_store_avg_check;

CREATE TABLE clickhouse.dwh.rpt_store_avg_check AS
SELECT
    from_utf8(s.store_name) AS store_name,
    from_utf8(s.store_city) AS store_city,
    from_utf8(s.store_country) AS store_country,
    AVG(f.sale_total_price) AS avg_check,
    COUNT(*) AS total_orders,
    SUM(f.sale_total_price) AS total_revenue
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_stores s
    ON f.store_id = s.store_id
WHERE f.store_id != -1
GROUP BY
    s.store_name,
    s.store_city,
    s.store_country
ORDER BY avg_check DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_5_suppliers;

CREATE TABLE clickhouse.dwh.rpt_top_5_suppliers AS
SELECT
    from_utf8(p.supplier_name) AS supplier_name,
    from_utf8(p.supplier_country) AS supplier_country,
    COUNT(DISTINCT f.product_id) AS product_count,
    SUM(f.sale_quantity) AS total_quantity,
    SUM(f.sale_total_price) AS total_revenue
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_products p
    ON f.product_id = p.product_id
    AND f.product_source = p.source
WHERE from_utf8(p.supplier_name) != ''
GROUP BY
    p.supplier_name,
    p.supplier_country
ORDER BY total_revenue DESC
LIMIT 5;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_supplier_avg_price;

CREATE TABLE clickhouse.dwh.rpt_supplier_avg_price AS
SELECT
    from_utf8(supplier_name) AS supplier_name,
    from_utf8(supplier_country) AS supplier_country,
    COUNT(DISTINCT product_id) AS product_count,
    AVG(CAST(from_utf8(product_price) AS DOUBLE)) AS avg_product_price
FROM clickhouse.dwh.dim_products
WHERE from_utf8(supplier_name) != ''
GROUP BY
    supplier_name,
    supplier_country
ORDER BY avg_product_price DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_sales_by_supplier_country;

CREATE TABLE clickhouse.dwh.rpt_sales_by_supplier_country AS
SELECT
    from_utf8(p.supplier_country) AS supplier_country,
    COUNT(DISTINCT from_utf8(p.supplier_name)) AS supplier_count,
    SUM(f.sale_total_price) AS total_revenue
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_products p
    ON f.product_id = p.product_id
    AND f.product_source = p.source
WHERE from_utf8(p.supplier_country) != ''
GROUP BY p.supplier_country
ORDER BY total_revenue DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_bottom_rated;

CREATE TABLE clickhouse.dwh.rpt_top_bottom_rated AS
SELECT
    product_id,
    product_name,
    product_category,
    CAST(from_utf8(product_rating) AS DOUBLE) AS product_rating,
    CAST(from_utf8(product_reviews) AS INTEGER) AS product_reviews,
    to_utf8('Top 5 Highest Rated') AS rating_category
FROM clickhouse.dwh.dim_products
WHERE 1=0;

INSERT INTO clickhouse.dwh.rpt_top_bottom_rated
SELECT
    product_id,
    product_name,
    product_category,
    CAST(from_utf8(product_rating) AS DOUBLE),
    CAST(from_utf8(product_reviews) AS INTEGER),
    to_utf8('Top 5 Highest Rated')
FROM clickhouse.dwh.dim_products
WHERE product_rating IS NOT NULL
ORDER BY CAST(from_utf8(product_rating) AS DOUBLE) DESC
LIMIT 5;

INSERT INTO clickhouse.dwh.rpt_top_bottom_rated
SELECT
    product_id,
    product_name,
    product_category,
    CAST(from_utf8(product_rating) AS DOUBLE),
    CAST(from_utf8(product_reviews) AS INTEGER),
    to_utf8('Bottom 5 Lowest Rated')
FROM clickhouse.dwh.dim_products
WHERE product_rating IS NOT NULL
ORDER BY CAST(from_utf8(product_rating) AS DOUBLE) ASC
LIMIT 5;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_rating_vs_sales;

CREATE TABLE clickhouse.dwh.rpt_rating_vs_sales AS
SELECT
    CAST(
        ROUND(
            CAST(from_utf8(p.product_rating) AS DOUBLE),
        0)
    AS INTEGER) AS rating_score,
    COUNT(DISTINCT p.product_id) AS product_count,
    AVG(COALESCE(f.sale_quantity,0)) AS avg_quantity_sold,
    SUM(COALESCE(f.sale_quantity,0)) AS total_quantity_sold
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f
    ON p.product_id = f.product_id
    AND p.source = f.product_source
WHERE p.product_rating IS NOT NULL
GROUP BY
    CAST(
        ROUND(
            CAST(from_utf8(p.product_rating) AS DOUBLE),
        0)
    AS INTEGER)
ORDER BY rating_score DESC;


DROP TABLE IF EXISTS clickhouse.dwh.rpt_most_reviewed;

CREATE TABLE clickhouse.dwh.rpt_most_reviewed AS
SELECT
    product_id,
    product_name,
    product_category,
    CAST(from_utf8(product_rating) AS DOUBLE) AS product_rating,
    CAST(from_utf8(product_reviews) AS INTEGER) AS product_reviews
FROM clickhouse.dwh.dim_products
ORDER BY product_reviews DESC
LIMIT 20;