import psycopg2
import csv
from glob import glob

conn = psycopg2.connect(
    host="postgres",
    database="mockdb",
    user="admin",
    password="admin123"
)
cur = conn.cursor()

cur.execute("TRUNCATE TABLE mock_data")
conn.commit()

all_files = sorted(glob('data/MOCK_DATA*.csv'))
postgres_files = []
for f in all_files:
    if 'MOCK_DATA.csv' == f.split('/')[-1]:  
        postgres_files.append(f)
    elif ' (1).csv' in f or ' (2).csv' in f or ' (3).csv' in f or ' (4).csv' in f:
        postgres_files.append(f)

print(f"PostgreSQL files: {postgres_files}")

for file_path in postgres_files:
    print(f"Processing {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            cur.execute("""
                INSERT INTO mock_data VALUES (
                    %(id)s, %(customer_first_name)s, %(customer_last_name)s, %(customer_age)s,
                    %(customer_email)s, %(customer_country)s, %(customer_postal_code)s,
                    %(customer_pet_type)s, %(customer_pet_name)s, %(customer_pet_breed)s,
                    %(seller_first_name)s, %(seller_last_name)s, %(seller_email)s,
                    %(seller_country)s, %(seller_postal_code)s,
                    %(product_name)s, %(product_category)s, %(product_price)s, %(product_quantity)s,
                    %(sale_date)s, %(sale_customer_id)s, %(sale_seller_id)s, %(sale_product_id)s,
                    %(sale_quantity)s, %(sale_total_price)s,
                    %(store_name)s, %(store_location)s, %(store_city)s, %(store_state)s,
                    %(store_country)s, %(store_phone)s, %(store_email)s,
                    %(pet_category)s, %(product_weight)s, %(product_color)s, %(product_size)s,
                    %(product_brand)s, %(product_material)s, %(product_description)s,
                    %(product_rating)s, %(product_reviews)s, %(product_release_date)s,
                    %(product_expiry_date)s,
                    %(supplier_name)s, %(supplier_contact)s, %(supplier_email)s,
                    %(supplier_phone)s, %(supplier_address)s, %(supplier_city)s, %(supplier_country)s
                )
            """, row)
    conn.commit()
    print(f"  {file_path} imported successfully")

cur.close()
conn.close()
print("PostgreSQL import completed!")