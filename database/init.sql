-- Инициализация базы данных users_db
CREATE DATABASE IF NOT EXISTS users_db;
USE users_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email, age) VALUES
('John Doe', 'john.doe@example.com', 30),
('Jane Smith', 'jane.smith@example.com', 25),
('Bob Johnson', 'bob.johnson@example.com', 35)
ON DUPLICATE KEY UPDATE name = VALUES(name), age = VALUES(age);

-- Инициализация базы данных products_db
CREATE DATABASE IF NOT EXISTS products_db;
USE products_db;

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100),
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, price, category, stock) VALUES
('Laptop Pro', 1299.99, 'Electronics', 15),
('Wireless Mouse', 29.99, 'Electronics', 50),
('Desk Lamp', 34.99, 'Home', 20),
('Coffee Maker', 89.99, 'Home', 10),
('Running Shoes', 79.99, 'Sports', 15)
ON DUPLICATE KEY UPDATE 
    price = VALUES(price),
    stock = VALUES(stock),
    category = VALUES(category);
