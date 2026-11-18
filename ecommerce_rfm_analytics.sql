CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(60),
    signup_date DATE
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(60),
    unit_cost DECIMAL(10,2),
    selling_price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_status ENUM('Completed', 'Returned', 'Cancelled'),
    payment_method VARCHAR(40),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    discount_pct DECIMAL(5,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO customers VALUES
(1, 'Aarav Sharma', 'Hyderabad', '2026-01-10'),
(2, 'Priya Nair', 'Bengaluru', '2026-01-18'),
(3, 'Rohan Verma', 'Chennai', '2026-02-05'),
(4, 'Sneha Reddy', 'Hyderabad', '2026-02-20'),
(5, 'Vikram Joshi', 'Mumbai', '2026-03-02'),
(6, 'Ananya Rao', 'Bengaluru', '2026-03-15'),
(7, 'Karthik Menon', 'Kochi', '2026-04-08'),
(8, 'Divya Patel', 'Ahmedabad', '2026-05-12');

INSERT INTO products VALUES
(101, 'ProBook Laptop 15', 'Electronics', 42000.00, 56000.00),
(102, 'NoiseCancel ANC Headphones', 'Accessories', 3200.00, 5500.00),
(103, 'UltraWide 27 Monitor', 'Electronics', 14000.00, 19500.00),
(104, 'Mechanical RGB Keyboard', 'Accessories', 2100.00, 3800.00),
(105, 'Flagship 5G Smartphone', 'Electronics', 26000.00, 35000.00),
(106, 'Ergonomic Wireless Mouse', 'Accessories', 900.00, 1800.00);

INSERT INTO orders VALUES
(1001, 1, '2026-06-05', 'Completed', 'UPI'),
(1002, 2, '2026-06-14', 'Completed', 'Credit Card'),
(1003, 3, '2026-06-22', 'Returned', 'Debit Card'),
(1004, 1, '2026-07-08', 'Completed', 'UPI'),
(1005, 4, '2026-07-19', 'Completed', 'Net Banking'),
(1006, 5, '2026-07-28', 'Completed', 'Credit Card'),
(1007, 2, '2026-08-04', 'Completed', 'UPI'),
(1008, 6, '2026-08-16', 'Returned', 'Credit Card'),
(1009, 1, '2026-08-25', 'Completed', 'UPI'),
(1010, 7, '2026-09-09', 'Completed', 'Debit Card'),
(1011, 4, '2026-09-21', 'Completed', 'UPI'),
(1012, 8, '2026-10-03', 'Cancelled', 'UPI'),
(1013, 2, '2026-10-15', 'Completed', 'Credit Card'),
(1014, 1, '2026-11-02', 'Completed', 'UPI'),
(1015, 6, '2026-11-11', 'Completed', 'Credit Card');

INSERT INTO order_items VALUES
(1, 1001, 101, 1, 5.00),
(2, 1001, 106, 1, 0.00),
(3, 1002, 105, 1, 0.00),
(4, 1003, 103, 1, 10.00),
(5, 1004, 102, 2, 5.00),
(6, 1005, 101, 1, 0.00),
(7, 1006, 103, 2, 8.00),
(8, 1007, 104, 2, 0.00),
(9, 1008, 105, 1, 5.00),
(10, 1009, 103, 1, 0.00),
(11, 1010, 102, 3, 10.00),
(12, 1011, 105, 1, 5.00),
(13, 1012, 104, 1, 0.00),
(14, 1013, 101, 1, 4.00),
(15, 1014, 102, 1, 0.00),
(16, 1015, 106, 3, 0.00);

USE ecommerce_analytics;

-- VIEW 1: RFM Customer Segmentation
CREATE OR REPLACE VIEW v_rfm_segments AS
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.city,
        DATEDIFF('2026-11-17', MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.quantity * p.selling_price * (1 - oi.discount_pct/100)), 2) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name, c.city
),
rfm_scores AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM customer_metrics
)
SELECT 
    customer_id, customer_name, city, recency_days, frequency, monetary_value,
    (r_score + f_score + m_score) AS rfm_total,
    CASE 
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 7 THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 5 THEN 'Potential Loyalist'
        ELSE 'At-Risk'
    END AS segment
FROM rfm_scores;

-- VIEW 2: Monthly Revenue, Gross Profit, MoM Growth % & Cumulative YTD
CREATE OR REPLACE VIEW v_monthly_kpis AS
WITH monthly_base AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        ROUND(SUM(oi.quantity * p.selling_price * (1 - oi.discount_pct/100)), 2) AS net_revenue,
        ROUND(SUM(oi.quantity * (p.selling_price * (1 - oi.discount_pct/100) - p.unit_cost)), 2) AS gross_profit
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT 
    order_month,
    completed_orders,
    net_revenue,
    gross_profit,
    ROUND((gross_profit / net_revenue) * 100, 1) AS gross_margin_pct,
    ROUND(
        ((net_revenue - LAG(net_revenue) OVER (ORDER BY order_month)) / 
         LAG(net_revenue) OVER (ORDER BY order_month)) * 100, 1
    ) AS mom_growth_pct,
    SUM(net_revenue) OVER (ORDER BY order_month) AS cumulative_revenue
FROM monthly_base;

-- VIEW 3: Product Margin & Return Rate Breakdown
CREATE OR REPLACE VIEW v_product_performance AS
SELECT 
    p.product_name,
    p.category,
    SUM(CASE WHEN o.order_status = 'Completed' THEN oi.quantity ELSE 0 END) AS units_sold,
    ROUND(SUM(CASE WHEN o.order_status = 'Completed' 
        THEN oi.quantity * p.selling_price * (1 - oi.discount_pct/100) ELSE 0 END), 2) AS net_revenue,
    ROUND(SUM(CASE WHEN o.order_status = 'Completed' 
        THEN oi.quantity * (p.selling_price * (1 - oi.discount_pct/100) - p.unit_cost) ELSE 0 END), 2) AS gross_profit,
    ROUND(
        (SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) / COUNT(DISTINCT o.order_id)) * 100, 1
    ) AS return_rate_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_name, p.category;

SELECT * FROM v_rfm_segments;
select * from v_monthly_kpis;
select * from v_product_performance;