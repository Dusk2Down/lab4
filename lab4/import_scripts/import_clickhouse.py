from clickhouse_driver import Client
import csv
from glob import glob
from datetime import datetime

client = Client(
    host='clickhouse',
    user='admin',
    password='admin123'
)


client.execute("TRUNCATE TABLE IF EXISTS default.mock_data")

def parse_date(date_str):
    if not date_str or date_str == '':
        return None
    try:
        for fmt in ['%m/%d/%Y', '%Y-%m-%d', '%d/%m/%Y', '%m/%d/%y']:
            try:
                return datetime.strptime(date_str, fmt).date()
            except:
                continue
        return None
    except:
        return None

def safe_float(val):
    try:
        return float(val) if val and str(val).strip() else 0.0
    except:
        return 0.0

def safe_int(val):
    try:
        return int(float(val)) if val and str(val).strip() else 0
    except:
        return 0

def safe_string(val):
    return str(val) if val and str(val).strip() else ''


all_files = sorted(glob('data/MOCK_DATA*.csv'))
clickhouse_files = []
for f in all_files:
    if ' (5).csv' in f or ' (6).csv' in f or ' (7).csv' in f or ' (8).csv' in f or ' (9).csv' in f:
        clickhouse_files.append(f)

print(f"ClickHouse files: {clickhouse_files}")

total_rows = 0
for file_path in clickhouse_files:
    print(f"Processing {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = []
        for row in reader:
            row_data = (
                safe_int(row.get('id')),
                safe_string(row.get('customer_first_name')),
                safe_string(row.get('customer_last_name')),
                safe_int(row.get('customer_age')),
                safe_string(row.get('customer_email')),
                safe_string(row.get('customer_country')),
                safe_string(row.get('customer_postal_code')),
                safe_string(row.get('customer_pet_type')),
                safe_string(row.get('customer_pet_name')),
                safe_string(row.get('customer_pet_breed')),
                safe_string(row.get('seller_first_name')),
                safe_string(row.get('seller_last_name')),
                safe_string(row.get('seller_email')),
                safe_string(row.get('seller_country')),
                safe_string(row.get('seller_postal_code')),
                safe_string(row.get('product_name')),
                safe_string(row.get('product_category')),
                safe_float(row.get('product_price')),
                safe_int(row.get('product_quantity')),
                parse_date(row.get('sale_date')),
                safe_int(row.get('sale_customer_id')),
                safe_int(row.get('sale_seller_id')),
                safe_int(row.get('sale_product_id')),
                safe_int(row.get('sale_quantity')),
                safe_float(row.get('sale_total_price')),
                safe_string(row.get('store_name')),
                safe_string(row.get('store_location')),
                safe_string(row.get('store_city')),
                safe_string(row.get('store_state')),
                safe_string(row.get('store_country')),
                safe_string(row.get('store_phone')),
                safe_string(row.get('store_email')),
                safe_string(row.get('pet_category')),
                safe_float(row.get('product_weight')),
                safe_string(row.get('product_color')),
                safe_string(row.get('product_size')),
                safe_string(row.get('product_brand')),
                safe_string(row.get('product_material')),
                safe_string(row.get('product_description')),
                safe_float(row.get('product_rating')),
                safe_int(row.get('product_reviews')),
                parse_date(row.get('product_release_date')),
                parse_date(row.get('product_expiry_date')),
                safe_string(row.get('supplier_name')),
                safe_string(row.get('supplier_contact')),
                safe_string(row.get('supplier_email')),
                safe_string(row.get('supplier_phone')),
                safe_string(row.get('supplier_address')),
                safe_string(row.get('supplier_city')),
                safe_string(row.get('supplier_country'))
            )
            rows.append(row_data)
        
        if rows:
            client.execute("INSERT INTO default.mock_data VALUES", rows)
            print(f"  Inserted {len(rows)} rows from {file_path}")
            total_rows += len(rows)

print(f"ClickHouse import completed! Total rows: {total_rows}")


result = client.execute("SELECT COUNT(*) FROM default.mock_data")
print(f"Total rows in ClickHouse mock_data: {result[0][0]}")