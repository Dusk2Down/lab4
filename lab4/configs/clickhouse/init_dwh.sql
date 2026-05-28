CREATE DATABASE IF NOT EXISTS dwh;


USE dwh;


CREATE USER IF NOT EXISTS 'etl_user' IDENTIFIED BY 'etl_password';
GRANT ALL PRIVILEGES ON dwh.* TO 'etl_user';