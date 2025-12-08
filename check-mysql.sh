#!/bin/bash
echo "=== Checking MySQL ==="

# Проверим базы данных
docker-compose exec -T mysql mysql -u root -prootpassword -e "SHOW DATABASES;"

echo -e "\n=== Checking users ==="
docker-compose exec -T mysql mysql -u root -prootpassword -e "SELECT User, Host FROM mysql.user;"

echo -e "\n=== Creating databases and users ==="
docker-compose exec -T mysql mysql -u root -prootpassword << 'MYSQL_SCRIPT'
-- Создадим базы данных
CREATE DATABASE IF NOT EXISTS users_db;
CREATE DATABASE IF NOT EXISTS products_db;

-- Создадим пользователя
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON users_db.* TO 'app_user'@'%';
GRANT ALL PRIVILEGES ON products_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;

-- Проверим
SHOW DATABASES;
SELECT 'Users:' as '';
SELECT User, Host FROM mysql.user WHERE User LIKE 'app_user';
SELECT 'Grants for app_user:' as '';
SHOW GRANTS FOR 'app_user'@'%';
MYSQL_SCRIPT

echo -e "\n=== Checking tables ==="
docker-compose exec -T mysql mysql -u root -prootpassword users_db -e "SHOW TABLES;"
