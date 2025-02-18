

-- Create Database
CREATE DATABASE ECommerceDB;
USE ECommerceDB;

-- Customers Table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products Table
CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(255) NOT NULL,
    stock INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table
CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('Pending', 'Shipped', 'Delivered', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE
);

-- Order_Items Table
CREATE TABLE Order_Items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
);

-- Payments Table
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash on Delivery') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE
);

-- Shipping Table
CREATE TABLE Shipping (
    shipping_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    tracking_number VARCHAR(255) UNIQUE,
    carrier VARCHAR(255),
    status ENUM('Processing', 'Shipped', 'In Transit', 'Delivered') DEFAULT 'Processing',
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE
);

-- Indexing for Performance Optimization
CREATE INDEX idx_customer_email ON Customers(email);
CREATE INDEX idx_product_category ON Products(category);
CREATE INDEX idx_order_customer ON Orders(customer_id);
CREATE INDEX idx_order_status ON Orders(status);
CREATE INDEX idx_order_items_order ON Order_Items(order_id);
CREATE INDEX idx_order_items_product ON Order_Items(product_id);

-- View: Get Customer Order Summary
CREATE VIEW Customer_Order_Summary AS
SELECT 
    c.customer_id, c.name, c.email, o.order_id, o.order_date, o.total_amount, o.status
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id;

-- Stored Procedure: Get Total Sales by Product
DELIMITER $$
CREATE PROCEDURE GetTotalSalesByProduct()
BEGIN
    SELECT p.name, SUM(oi.quantity) AS total_sold, SUM(oi.subtotal) AS revenue
    FROM Order_Items oi
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY p.name
    ORDER BY revenue DESC;
END $$
DELIMITER ;

-- Security: Restrict direct DELETE on Customers (Soft Delete Example)
ALTER TABLE Customers ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

UPDATE Customers SET is_deleted = TRUE WHERE customer_id = 1;

-- Triggers: Auto-update stock when an order is placed
DELIMITER $$
CREATE TRIGGER ReduceStockAfterOrder
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
    UPDATE Products SET stock = stock - NEW.quantity WHERE product_id = NEW.product_id;
END $$
DELIMITER ;

-- Sample Data Insertion
INSERT INTO Customers (name, email, phone, address) VALUES 
('Alice Johnson', 'alice@example.com', '1234567890', '456 Maple St, Boston'),
('Bob Smith', 'bob@example.com', '9876543210', '789 Oak St, Chicago');

INSERT INTO Products (name, description, price, category, stock) VALUES 
('Laptop', '15-inch screen, 8GB RAM, 512GB SSD', 1200.00, 'Electronics', 50),
('Smartphone', '6.5-inch display, 128GB storage, 5G', 800.00, 'Electronics', 100),
('Headphones', 'Wireless noise-canceling over-ear headphones', 150.00, 'Accessories', 200);

INSERT INTO Orders (customer_id, total_amount) VALUES 
(1, 1200.00), (2, 800.00);

INSERT INTO Order_Items (order_id, product_id, quantity, subtotal) VALUES 
(1, 1, 1, 1200.00), (2, 2, 1, 800.00);

INSERT INTO Payments (order_id, payment_method, status) VALUES 
(1, 'Credit Card', 'Completed'), (2, 'PayPal', 'Pending');

INSERT INTO Shipping (order_id, tracking_number, carrier, status) VALUES 
(1, '1Z999AA10123456784', 'UPS', 'Shipped'), (2, '1Z999BB20234567890', 'FedEx', 'Processing');

