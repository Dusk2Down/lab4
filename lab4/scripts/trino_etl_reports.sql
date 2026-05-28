
DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_10_products;
CREATE TABLE clickhouse.dwh.rpt_top_10_products AS
SELECT 
    p.product_id,
    p.product_name,
    p.product_category,
    SUM(f.sale_quantity) as total_quantity_sold,
    SUM(f.sale_total_price) as total_revenue,
    COUNT(DISTINCT f.customer_id) as unique_customers,
    AVG(p.product_rating) as avg_rating
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_products p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY total_quantity_sold DESC
LIMIT 10;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_revenue_by_category;
CREATE TABLE clickhouse.dwh.rpt_revenue_by_category AS
SELECT 
    p.product_category,
    COUNT(DISTINCT p.product_id) as product_count,
    SUM(f.sale_quantity) as total_quantity_sold,
    SUM(f.sale_total_price) as total_revenue,
    AVG(f.sale_total_price) as avg_revenue_per_sale,
    RANK() OVER (ORDER BY SUM(f.sale_total_price) DESC) as revenue_rank
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_products p ON f.product_id = p.product_id
GROUP BY p.product_category
ORDER BY total_revenue DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_product_ratings;
CREATE TABLE clickhouse.dwh.rpt_product_ratings AS
SELECT 
    p.product_id,
    p.product_name,
    p.product_category,
    p.product_rating,
    p.product_reviews,
    SUM(f.sale_quantity) as total_sold,
    CASE 
        WHEN p.product_reviews > 100 THEN 'High Reviews'
        WHEN p.product_reviews > 50 THEN 'Medium Reviews'
        ELSE 'Low Reviews'
    END as review_category,
    CASE 
        WHEN p.product_rating >= 4.0 THEN 'Excellent'
        WHEN p.product_rating >= 3.0 THEN 'Good'
        WHEN p.product_rating >= 2.0 THEN 'Average'
        ELSE 'Poor'
    END as rating_category
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
GROUP BY p.product_id, p.product_name, p.product_category, 
         p.product_rating, p.product_reviews
ORDER BY p.product_rating DESC, total_sold DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_10_customers;
CREATE TABLE clickhouse.dwh.rpt_top_10_customers AS
SELECT 
    c.customer_id,
    c.customer_full_name,
    c.customer_country,
    c.customer_age,
    COUNT(DISTINCT f.date_id) as days_with_purchases,
    COUNT(*) as total_transactions,
    SUM(f.sale_total_price) as total_spent,
    AVG(f.sale_total_price) as avg_transaction_value,
    SUM(f.sale_quantity) as total_items_bought
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_full_name, c.customer_country, c.customer_age
ORDER BY total_spent DESC
LIMIT 10;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_customers_by_country;
CREATE TABLE clickhouse.dwh.rpt_customers_by_country AS
SELECT 
    c.customer_country,
    COUNT(DISTINCT c.customer_id) as customer_count,
    SUM(f.sale_total_price) as total_revenue,
    AVG(f.sale_total_price) as avg_spent_per_customer,
    COUNT(*) as total_orders,
    ROUND(SUM(f.sale_total_price) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2) as revenue_per_customer,
    RANK() OVER (ORDER BY SUM(f.sale_total_price) DESC) as country_rank
FROM clickhouse.dwh.dim_customers c
LEFT JOIN clickhouse.dwh.fact_sales f ON c.customer_id = f.customer_id
GROUP BY c.customer_country
ORDER BY total_revenue DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_customer_avg_check;
CREATE TABLE clickhouse.dwh.rpt_customer_avg_check AS
SELECT 
    c.customer_id,
    c.customer_full_name,
    c.customer_country,
    COUNT(DISTINCT f.date_id) as purchase_days,
    COUNT(*) as total_orders,
    SUM(f.sale_total_price) as total_spent,
    ROUND(AVG(f.sale_total_price), 2) as avg_check,
    MAX(f.sale_total_price) as max_check,
    MIN(f.sale_total_price) as min_check,
    ROUND(STDDEV(f.sale_total_price), 2) as stddev_check,
    CASE 
        WHEN AVG(f.sale_total_price) > 500 THEN 'VIP'
        WHEN AVG(f.sale_total_price) > 200 THEN 'Premium'
        WHEN AVG(f.sale_total_price) > 100 THEN 'Regular'
        ELSE 'Budget'
    END as customer_segment
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_full_name, c.customer_country
ORDER BY avg_check DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_sales_trends;
CREATE TABLE clickhouse.dwh.rpt_sales_trends AS
SELECT 
    d.year,
    d.month,
    d.season,
    COUNT(DISTINCT f.sale_id) as order_count,
    SUM(f.sale_quantity) as total_quantity,
    SUM(f.sale_total_price) as total_revenue,
    AVG(f.sale_total_price) as avg_order_value,
    COUNT(DISTINCT f.customer_id) as unique_customers,
    LAG(SUM(f.sale_total_price)) OVER (PARTITION BY d.year ORDER BY d.month) as prev_month_revenue,
    ROUND(
        ((SUM(f.sale_total_price) - LAG(SUM(f.sale_total_price)) OVER (PARTITION BY d.year ORDER BY d.month)) 
        / NULLIF(LAG(SUM(f.sale_total_price)) OVER (PARTITION BY d.year ORDER BY d.month), 0)) * 100,
    2) as mom_growth_pct
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.season
ORDER BY d.year, d.month;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_period_comparison;
CREATE TABLE clickhouse.dwh.rpt_period_comparison AS
WITH yearly_data AS (
    SELECT 
        d.year,
        SUM(f.sale_total_price) as yearly_revenue,
        COUNT(*) as yearly_orders,
        COUNT(DISTINCT f.customer_id) as yearly_customers
    FROM clickhouse.dwh.fact_sales f
    JOIN clickhouse.dwh.dim_date d ON f.date_id = d.date_id
    GROUP BY d.year
),
quarterly_data AS (
    SELECT 
        d.year,
        d.quarter,
        SUM(f.sale_total_price) as quarterly_revenue,
        COUNT(*) as quarterly_orders
    FROM clickhouse.dwh.fact_sales f
    JOIN clickhouse.dwh.dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.quarter
)
SELECT 
    'Yearly' as period_type,
    CAST(y.year AS VARCHAR) as period,
    y.yearly_revenue as revenue,
    y.yearly_orders as orders,
    y.yearly_customers as customers,
    NULL as prev_period_revenue,
    NULL as growth_pct
FROM yearly_data y
UNION ALL
SELECT 
    'Quarterly' as period_type,
    CONCAT(CAST(q.year AS VARCHAR), '-Q', CAST(q.quarter AS VARCHAR)) as period,
    q.quarterly_revenue as revenue,
    q.quarterly_orders as orders,
    NULL as customers,
    LAG(q.quarterly_revenue) OVER (ORDER BY q.year, q.quarter) as prev_period_revenue,
    ROUND(
        ((q.quarterly_revenue - LAG(q.quarterly_revenue) OVER (ORDER BY q.year, q.quarter)) 
        / NULLIF(LAG(q.quarterly_revenue) OVER (ORDER BY q.year, q.quarter), 0)) * 100,
    2) as growth_pct
FROM quarterly_data q;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_avg_order_size_monthly;
CREATE TABLE clickhouse.dwh.rpt_avg_order_size_monthly AS
SELECT 
    d.year,
    d.month,
    d.season,
    COUNT(*) as order_count,
    ROUND(AVG(f.sale_quantity), 2) as avg_items_per_order,
    ROUND(AVG(f.sale_total_price), 2) as avg_order_value,
    ROUND(SUM(f.sale_total_price) / NULLIF(COUNT(DISTINCT f.customer_id), 0), 2) as avg_spent_per_customer,
    ROUND(AVG(f.sale_total_price / NULLIF(f.sale_quantity, 0)), 2) as avg_price_per_item
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.season
ORDER BY d.year, d.month;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_5_stores;
CREATE TABLE clickhouse.dwh.rpt_top_5_stores AS
SELECT 
    s.store_id,
    s.store_name,
    s.store_city,
    s.store_country,
    COUNT(DISTINCT f.customer_id) as unique_customers,
    COUNT(*) as total_transactions,
    SUM(f.sale_total_price) as total_revenue,
    AVG(f.sale_total_price) as avg_transaction_value,
    SUM(f.sale_quantity) as total_items_sold,
    RANK() OVER (ORDER BY SUM(f.sale_total_price) DESC) as revenue_rank
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_stores s ON f.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.store_city, s.store_country
ORDER BY total_revenue DESC
LIMIT 5;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_sales_by_location;
CREATE TABLE clickhouse.dwh.rpt_sales_by_location AS
SELECT 
    s.store_country,
    s.store_city,
    COUNT(DISTINCT s.store_id) as store_count,
    COUNT(*) as total_orders,
    SUM(f.sale_total_price) as total_revenue,
    AVG(f.sale_total_price) as avg_order_value,
    COUNT(DISTINCT f.customer_id) as unique_customers,
    RANK() OVER (PARTITION BY s.store_country ORDER BY SUM(f.sale_total_price) DESC) as city_rank_in_country
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_stores s ON f.store_id = s.store_id
GROUP BY s.store_country, s.store_city
ORDER BY s.store_country, total_revenue DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_store_avg_check;
CREATE TABLE clickhouse.dwh.rpt_store_avg_check AS
SELECT 
    s.store_id,
    s.store_name,
    s.store_city,
    s.store_country,
    COUNT(*) as total_orders,
    SUM(f.sale_total_price) as total_revenue,
    ROUND(AVG(f.sale_total_price), 2) as avg_check,
    MAX(f.sale_total_price) as max_check,
    MIN(f.sale_total_price) as min_check,
    ROUND(AVG(f.sale_quantity), 2) as avg_items_per_order,
    ROUND(SUM(f.sale_total_price) / NULLIF(COUNT(DISTINCT f.customer_id), 0), 2) as revenue_per_customer
FROM clickhouse.dwh.fact_sales f
JOIN clickhouse.dwh.dim_stores s ON f.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.store_city, s.store_country
ORDER BY avg_check DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_5_suppliers;
CREATE TABLE clickhouse.dwh.rpt_top_5_suppliers AS
SELECT 
    p.supplier_name,
    p.supplier_country,
    COUNT(DISTINCT p.product_id) as product_count,
    COUNT(DISTINCT f.product_id) as products_sold,
    SUM(f.sale_quantity) as total_quantity_sold,
    SUM(f.sale_total_price) as total_revenue,
    AVG(p.product_price) as avg_product_price,
    RANK() OVER (ORDER BY SUM(f.sale_total_price) DESC) as revenue_rank
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
GROUP BY p.supplier_name, p.supplier_country
ORDER BY total_revenue DESC
LIMIT 5;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_supplier_avg_prices;
CREATE TABLE clickhouse.dwh.rpt_supplier_avg_prices AS
SELECT 
    p.supplier_name,
    p.supplier_country,
    COUNT(DISTINCT p.product_id) as total_products,
    MIN(p.product_price) as min_price,
    MAX(p.product_price) as max_price,
    AVG(p.product_price) as avg_price,
    STDDEV(p.product_price) as stddev_price,
    SUM(f.sale_quantity) as total_units_sold,
    SUM(f.sale_total_price) as total_revenue
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
GROUP BY p.supplier_name, p.supplier_country
ORDER BY avg_price DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_sales_by_supplier_country;
CREATE TABLE clickhouse.dwh.rpt_sales_by_supplier_country AS
SELECT 
    p.supplier_country,
    COUNT(DISTINCT p.supplier_name) as unique_suppliers,
    COUNT(DISTINCT p.product_id) as total_products,
    SUM(f.sale_quantity) as total_quantity_sold,
    SUM(f.sale_total_price) as total_revenue,
    AVG(p.product_rating) as avg_product_rating,
    RANK() OVER (ORDER BY SUM(f.sale_total_price) DESC) as revenue_rank,
    RANK() OVER (ORDER BY COUNT(DISTINCT p.supplier_name) DESC) as supplier_count_rank
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
GROUP BY p.supplier_country
ORDER BY total_revenue DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_top_bottom_rated_products;
CREATE TABLE clickhouse.dwh.rpt_top_bottom_rated_products AS
WITH ranked_products AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        p.product_rating,
        p.product_reviews,
        SUM(f.sale_quantity) as total_sold,
        SUM(f.sale_total_price) as total_revenue,
        ROW_NUMBER() OVER (ORDER BY p.product_rating DESC) as rating_rank_high,
        ROW_NUMBER() OVER (ORDER BY p.product_rating ASC) as rating_rank_low
    FROM clickhouse.dwh.dim_products p
    LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
    GROUP BY p.product_id, p.product_name, p.product_category, p.product_rating, p.product_reviews
)
SELECT 
    product_id,
    product_name,
    product_category,
    product_rating,
    product_reviews,
    total_sold,
    total_revenue,
    CASE 
        WHEN rating_rank_high <= 5 THEN 'Top 5 Highest Rated'
        WHEN rating_rank_low <= 5 THEN 'Bottom 5 Lowest Rated'
        ELSE 'Other'
    END as rating_category
FROM ranked_products
WHERE rating_rank_high <= 5 OR rating_rank_low <= 5
ORDER BY product_rating DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_rating_vs_sales_correlation;
CREATE TABLE clickhouse.dwh.rpt_rating_vs_sales_correlation AS
SELECT 
    ROUND(p.product_rating, 1) as rating_bucket,
    COUNT(DISTINCT p.product_id) as product_count,
    AVG(COALESCE(f.sale_quantity, 0)) as avg_units_sold,
    AVG(COALESCE(f.sale_total_price, 0)) as avg_revenue,
    AVG(p.product_reviews) as avg_reviews,
    SUM(COALESCE(f.sale_quantity, 0)) as total_units_sold,
    SUM(COALESCE(f.sale_total_price, 0)) as total_revenue
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
GROUP BY ROUND(p.product_rating, 1)
ORDER BY rating_bucket DESC;

DROP TABLE IF EXISTS clickhouse.dwh.rpt_most_reviewed_products;
CREATE TABLE clickhouse.dwh.rpt_most_reviewed_products AS
SELECT 
    p.product_id,
    p.product_name,
    p.product_category,
    p.product_rating,
    p.product_reviews,
    SUM(COALESCE(f.sale_quantity, 0)) as total_sold,
    SUM(COALESCE(f.sale_total_price, 0)) as total_revenue,
    CASE 
        WHEN p.product_reviews > 500 THEN 'Very High'
        WHEN p.product_reviews > 200 THEN 'High'
        WHEN p.product_reviews > 50 THEN 'Medium'
        ELSE 'Low'
    END as review_volume_category
FROM clickhouse.dwh.dim_products p
LEFT JOIN clickhouse.dwh.fact_sales f ON p.product_id = f.product_id
GROUP BY p.product_id, p.product_name, p.product_category, p.product_rating, p.product_reviews
ORDER BY p.product_reviews DESC
LIMIT 20;

SELECT 'REPORTS CREATED SUCCESSFULLY!' as status;
SELECT 'rpt_top_10_products' as report_name, COUNT(*) as rows FROM clickhouse.dwh.rpt_top_10_products
UNION ALL SELECT 'rpt_revenue_by_category', COUNT(*) FROM clickhouse.dwh.rpt_revenue_by_category
UNION ALL SELECT 'rpt_product_ratings', COUNT(*) FROM clickhouse.dwh.rpt_product_ratings
UNION ALL SELECT 'rpt_top_10_customers', COUNT(*) FROM clickhouse.dwh.rpt_top_10_customers
UNION ALL SELECT 'rpt_customers_by_country', COUNT(*) FROM clickhouse.dwh.rpt_customers_by_country
UNION ALL SELECT 'rpt_customer_avg_check', COUNT(*) FROM clickhouse.dwh.rpt_customer_avg_check
UNION ALL SELECT 'rpt_sales_trends', COUNT(*) FROM clickhouse.dwh.rpt_sales_trends
UNION ALL SELECT 'rpt_period_comparison', COUNT(*) FROM clickhouse.dwh.rpt_period_comparison
UNION ALL SELECT 'rpt_avg_order_size_monthly', COUNT(*) FROM clickhouse.dwh.rpt_avg_order_size_monthly
UNION ALL SELECT 'rpt_top_5_stores', COUNT(*) FROM clickhouse.dwh.rpt_top_5_stores
UNION ALL SELECT 'rpt_sales_by_location', COUNT(*) FROM clickhouse.dwh.rpt_sales_by_location
UNION ALL SELECT 'rpt_store_avg_check', COUNT(*) FROM clickhouse.dwh.rpt_store_avg_check
UNION ALL SELECT 'rpt_top_5_suppliers', COUNT(*) FROM clickhouse.dwh.rpt_top_5_suppliers
UNION ALL SELECT 'rpt_supplier_avg_prices', COUNT(*) FROM clickhouse.dwh.rpt_supplier_avg_prices
UNION ALL SELECT 'rpt_sales_by_supplier_country', COUNT(*) FROM clickhouse.dwh.rpt_sales_by_supplier_country
UNION ALL SELECT 'rpt_top_bottom_rated_products', COUNT(*) FROM clickhouse.dwh.rpt_top_bottom_rated_products
UNION ALL SELECT 'rpt_rating_vs_sales_correlation', COUNT(*) FROM clickhouse.dwh.rpt_rating_vs_sales_correlation
UNION ALL SELECT 'rpt_most_reviewed_products', COUNT(*) FROM clickhouse.dwh.rpt_most_reviewed_products;