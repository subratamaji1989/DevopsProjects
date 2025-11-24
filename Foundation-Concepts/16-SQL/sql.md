# SQL Cheat Sheet (Beginner → Intermediate)

> Essential SQL commands, concepts, and patterns for database management, ETL processes, and data analysis.

---

## Table of Contents

1. [Introduction to SQL & Databases](#1-introduction-to-sql--databases)
2. [Sample Database Schema](#2-sample-database-schema)
3. [Data Types](#3-data-types)
4. [Basic Queries](#4-basic-queries)
5. [Filtering & Conditions](#5-filtering--conditions)
6. [Joins](#6-joins)
7. [Aggregations & Grouping](#7-aggregations--grouping)
8. [Subqueries](#8-subqueries)
9. [Data Manipulation](#9-data-manipulation)
10. [Table Operations](#10-table-operations)
11. [Indexes & Constraints](#11-indexes--constraints)
12. [Views & CTEs](#12-views--ctes)
13. [Window Functions](#13-window-functions)
14. [ETL Patterns](#14-etl-patterns)
15. [Performance & Optimization](#15-performance--optimization)
16. [Common Data Engineering Tasks](#16-common-data-engineering-tasks)
17. [Database-Specific Syntax & Features](#17-database-specific-syntax--features)
18. [Modern SQL Features](#18-modern-sql-features)
19. [Best Practices & Anti-Patterns](#19-best-practices--anti-patterns)
20. [Real-World Case Studies](#20-real-world-case-studies)
21. [Setting Up SQL Environment Locally](#21-setting-up-sql-environment-locally)

---

# 1. Introduction to SQL & Databases

* **SQL (Structured Query Language)**: Standard language for managing relational databases
* **Database Types**: PostgreSQL, MySQL, SQL Server, Oracle, SQLite, Redshift, BigQuery
* **Key Concepts**: Tables, Rows, Columns, Primary Keys, Foreign Keys, Relationships

```sql
-- Connect to database (varies by database system)
-- PostgreSQL: psql -h hostname -d database -U username
-- MySQL: mysql -h hostname -u username -p database
```

---

# 2. Sample Database Schema

* **E-commerce Database Schema** (used throughout examples):

```sql
-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INTEGER,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES users(user_id),
    order_date DATE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_method VARCHAR(50)
);

-- Order items table (junction table)
CREATE TABLE order_items (
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

-- Sample data insertion
INSERT INTO users (name, email, age) VALUES
('John Doe', 'john@example.com', 30),
('Jane Smith', 'jane@example.com', 25),
('Bob Johnson', 'bob@example.com', 35);

INSERT INTO products (name, category, price, stock_quantity) VALUES
('Laptop', 'Electronics', 999.99, 50),
('Book', 'Education', 29.99, 100),
('Headphones', 'Electronics', 79.99, 75);
```

---

# 3. Data Types

* **Numeric Types:**
  - `INTEGER/INT`: Whole numbers (-2,147,483,648 to 2,147,483,647)
  - `BIGINT`: Large integers
  - `SMALLINT`: Small integers
  - `DECIMAL/NUMERIC(precision, scale)`: Exact decimal numbers
  - `FLOAT/REAL`: Approximate decimal numbers

* **String Types:**
  - `VARCHAR(n)`: Variable-length strings (up to n characters)
  - `CHAR(n)`: Fixed-length strings (exactly n characters)
  - `TEXT`: Unlimited length strings

* **Date/Time Types:**
  - `DATE`: Date only (YYYY-MM-DD)
  - `TIME`: Time only (HH:MM:SS)
  - `TIMESTAMP`: Date and time with timezone
  - `TIMESTAMPTZ`: Timestamp with timezone

* **Boolean & Other:**
  - `BOOLEAN/BOOL`: True/False values
  - `JSON/JSONB`: JSON data (PostgreSQL)
  - `UUID`: Universally unique identifiers

---

# 4. Basic Queries

* **SELECT Statement:**

```sql
-- Select all columns
SELECT * FROM table_name;

-- Select specific columns
SELECT column1, column2, column3 FROM table_name;

-- Select with column aliases
SELECT column1 AS alias1, column2 AS alias2 FROM table_name;

-- Select distinct values
SELECT DISTINCT column1 FROM table_name;

-- Limit results
SELECT * FROM table_name LIMIT 10;

-- Count rows
SELECT COUNT(*) FROM table_name;
```

* **ORDER BY:**

```sql
-- Sort ascending (default)
SELECT * FROM table_name ORDER BY column1;

-- Sort descending
SELECT * FROM table_name ORDER BY column1 DESC;

-- Sort by multiple columns
SELECT * FROM table_name ORDER BY column1 ASC, column2 DESC;
```

---

# 5. Filtering & Conditions

* **WHERE Clause:**

```sql
-- Basic conditions
SELECT * FROM users WHERE age > 18;
SELECT * FROM products WHERE category = 'Electronics';

-- Multiple conditions with AND/OR
SELECT * FROM users WHERE age >= 18 AND status = 'active';
SELECT * FROM orders WHERE total > 100 OR payment_method = 'credit';

-- NOT operator
SELECT * FROM users WHERE NOT status = 'inactive';

-- IN operator
SELECT * FROM products WHERE category IN ('Electronics', 'Books', 'Clothing');

-- BETWEEN operator
SELECT * FROM orders WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';

-- LIKE operator (pattern matching)
SELECT * FROM users WHERE email LIKE '%@gmail.com';
SELECT * FROM products WHERE name LIKE 'Mac%';  -- Starts with 'Mac'
SELECT * FROM users WHERE name LIKE '%John%';   -- Contains 'John'

-- IS NULL / IS NOT NULL
SELECT * FROM users WHERE last_login IS NULL;
SELECT * FROM orders WHERE shipped_date IS NOT NULL;
```

---

# 6. Joins

* **INNER JOIN:** Returns only matching rows from both tables

```sql
SELECT u.name, o.order_id, o.total
FROM users u
INNER JOIN orders o ON u.user_id = o.user_id;
```

* **LEFT JOIN:** Returns all rows from left table, matching rows from right table

```sql
SELECT u.name, o.order_id, o.total
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id;
```

* **RIGHT JOIN:** Returns all rows from right table, matching rows from left table

```sql
SELECT u.name, o.order_id, o.total
FROM users u
RIGHT JOIN orders o ON u.user_id = o.user_id;
```

* **FULL OUTER JOIN:** Returns all rows from both tables

```sql
SELECT u.name, o.order_id, o.total
FROM users u
FULL OUTER JOIN orders o ON u.user_id = o.user_id;
```

* **CROSS JOIN:** Cartesian product of both tables

```sql
SELECT u.name, p.product_name
FROM users u
CROSS JOIN products p;
```

* **Multiple Joins:**

```sql
SELECT u.name, o.order_id, p.product_name, oi.quantity
FROM users u
INNER JOIN orders o ON u.user_id = o.user_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id;
```

---

# 7. Aggregations & Grouping

* **Aggregate Functions:**

```sql
-- COUNT: Count rows
SELECT COUNT(*) FROM orders;
SELECT COUNT(DISTINCT customer_id) FROM orders;

-- SUM: Sum values
SELECT SUM(total) FROM orders;
SELECT SUM(quantity) FROM order_items;

-- AVG: Average values
SELECT AVG(price) FROM products;
SELECT AVG(total) FROM orders WHERE order_date >= '2023-01-01';

-- MIN/MAX: Minimum/Maximum values
SELECT MIN(price), MAX(price) FROM products;
SELECT MIN(order_date), MAX(order_date) FROM orders;

-- GROUP BY: Group results
SELECT category, COUNT(*) as product_count
FROM products
GROUP BY category;

-- HAVING: Filter grouped results
SELECT category, AVG(price) as avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 50;

-- Multiple aggregations
SELECT
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as order_count,
    SUM(total) as total_revenue,
    AVG(total) as avg_order_value
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
```

---

# 8. Subqueries

* **Subquery in WHERE clause:**

```sql
-- Find customers who placed orders above average
SELECT customer_id, name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE total > (SELECT AVG(total) FROM orders)
);
```

* **Subquery in FROM clause (Derived table):**

```sql
SELECT category, avg_price, product_count
FROM (
    SELECT category, AVG(price) as avg_price, COUNT(*) as product_count
    FROM products
    GROUP BY category
) as category_stats
WHERE product_count > 10;
```

* **Subquery in SELECT clause:**

```sql
SELECT
    product_id,
    name,
    price,
    (SELECT AVG(price) FROM products) as overall_avg_price
FROM products;
```

* **EXISTS/NOT EXISTS:**

```sql
-- Find customers who have placed at least one order
SELECT customer_id, name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- Find products that have never been ordered
SELECT product_id, name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi
    WHERE oi.product_id = p.product_id
);
```

---

# 9. Data Manipulation

* **INSERT Statements:**

```sql
-- Insert single row
INSERT INTO users (name, email, created_at)
VALUES ('John Doe', 'john@example.com', CURRENT_TIMESTAMP);

-- Insert multiple rows
INSERT INTO users (name, email, created_at) VALUES
('Jane Smith', 'jane@example.com', CURRENT_TIMESTAMP),
('Bob Johnson', 'bob@example.com', CURRENT_TIMESTAMP);

-- Insert from SELECT
INSERT INTO archived_orders (order_id, customer_id, total, order_date)
SELECT order_id, customer_id, total, order_date
FROM orders
WHERE order_date < '2020-01-01';
```

* **UPDATE Statements:**

```sql
-- Update single column
UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = 123;

-- Update multiple columns
UPDATE products SET price = price * 1.1, updated_at = CURRENT_TIMESTAMP
WHERE category = 'Electronics';

-- Update with subquery
UPDATE users SET status = 'premium'
WHERE user_id IN (
    SELECT customer_id FROM orders
    GROUP BY customer_id
    HAVING SUM(total) > 1000
);
```

* **DELETE Statements:**

```sql
-- Delete specific rows
DELETE FROM users WHERE last_login < '2020-01-01';

-- Delete with subquery
DELETE FROM order_items
WHERE order_id IN (
    SELECT order_id FROM orders
    WHERE status = 'cancelled'
);

-- Truncate table (remove all rows)
TRUNCATE TABLE temp_data;
```

---

# 10. Table Operations

* **CREATE TABLE:**

```sql
-- Basic table creation
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create table with foreign key
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES users(user_id),
    order_date DATE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'
);
```

* **ALTER TABLE:**

```sql
-- Add column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Drop column
ALTER TABLE users DROP COLUMN phone;

-- Modify column
ALTER TABLE users ALTER COLUMN age TYPE SMALLINT;

-- Rename column
ALTER TABLE users RENAME COLUMN name TO full_name;

-- Add constraint
ALTER TABLE users ADD CONSTRAINT check_age CHECK (age >= 0);

-- Drop constraint
ALTER TABLE users DROP CONSTRAINT check_age;
```

* **DROP TABLE:**

```sql
-- Drop single table
DROP TABLE temp_users;

-- Drop with CASCADE (removes dependent objects)
DROP TABLE users CASCADE;

-- Check if exists before dropping
DROP TABLE IF EXISTS temp_users;
```

---

# 11. Indexes & Constraints

* **Primary Key Constraint:**

```sql
-- Single column primary key
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    name VARCHAR(100)
);

-- Composite primary key
CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    PRIMARY KEY (order_id, product_id)
);
```

* **Foreign Key Constraint:**

```sql
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES users(user_id)
);
```

* **Unique Constraint:**

```sql
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    username VARCHAR(50) UNIQUE
);
```

* **Check Constraint:**

```sql
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2) CHECK (price > 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);
```

* **Indexes:**

```sql
-- Single column index
CREATE INDEX idx_users_email ON users(email);

-- Composite index
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Unique index
CREATE UNIQUE INDEX idx_users_username ON users(username);

-- Drop index
DROP INDEX idx_users_email;
```

---

# 12. Views & CTEs

* **Views:**

```sql
-- Create view
CREATE VIEW active_users AS
SELECT user_id, name, email, created_at
FROM users
WHERE status = 'active';

-- Query view
SELECT * FROM active_users WHERE created_at > '2023-01-01';

-- Update view (if simple)
UPDATE active_users SET name = 'John Smith' WHERE user_id = 1;

-- Drop view
DROP VIEW active_users;
```

* **Common Table Expressions (CTEs):**

```sql
-- Simple CTE
WITH high_value_orders AS (
    SELECT customer_id, SUM(total) as total_spent
    FROM orders
    GROUP BY customer_id
    HAVING SUM(total) > 500
)
SELECT u.name, h.total_spent
FROM users u
JOIN high_value_orders h ON u.user_id = h.customer_id;

-- Recursive CTE (for hierarchical data)
WITH RECURSIVE employee_hierarchy AS (
    -- Base case
    SELECT employee_id, manager_id, name, 0 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case
    SELECT e.employee_id, e.manager_id, e.name, eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy ORDER BY level, name;
```

---

# 13. Window Functions

* **ROW_NUMBER, RANK, DENSE_RANK:**

```sql
-- Assign row numbers
SELECT
    product_id,
    name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) as row_num
FROM products;

-- Rank products by price within categories
SELECT
    category,
    name,
    price,
    RANK() OVER (PARTITION BY category ORDER BY price DESC) as price_rank
FROM products;
```

* **Running Totals & Moving Averages:**

```sql
-- Running total of sales
SELECT
    order_date,
    total,
    SUM(total) OVER (ORDER BY order_date) as running_total
FROM orders;

-- Moving average of last 7 days
SELECT
    order_date,
    daily_sales,
    AVG(daily_sales) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7d
FROM daily_sales;
```

* **LAG and LEAD:**

```sql
-- Compare with previous period
SELECT
    month,
    sales,
    LAG(sales) OVER (ORDER BY month) as prev_month_sales,
    (sales - LAG(sales) OVER (ORDER BY month)) as sales_change
FROM monthly_sales;

-- Compare with next period
SELECT
    month,
    sales,
    LEAD(sales) OVER (ORDER BY month) as next_month_sales
FROM monthly_sales;
```

---

# 14. ETL Patterns

* **Incremental Loading:**

```sql
-- Load new records since last ETL run
INSERT INTO fact_sales (customer_id, product_id, quantity, amount, sale_date)
SELECT customer_id, product_id, quantity, amount, sale_date
FROM staging_sales
WHERE sale_date > (SELECT MAX(sale_date) FROM fact_sales);
```

* **SCD Type 2 (Slowly Changing Dimensions):**

```sql
-- Insert new dimension records
INSERT INTO dim_customer (customer_id, name, email, address, start_date, end_date, is_current)
SELECT
    customer_id,
    name,
    email,
    address,
    CURRENT_DATE as start_date,
    '9999-12-31'::DATE as end_date,
    TRUE as is_current
FROM staging_customers sc
WHERE NOT EXISTS (
    SELECT 1 FROM dim_customer dc
    WHERE dc.customer_id = sc.customer_id
    AND dc.is_current = TRUE
);

-- Expire old records for changed customers
UPDATE dim_customer
SET end_date = CURRENT_DATE - INTERVAL '1 day',
    is_current = FALSE
WHERE customer_id IN (
    SELECT customer_id FROM staging_customers
)
AND is_current = TRUE;
```

* **Data Quality Checks:**

```sql
-- Check for duplicates
SELECT customer_id, COUNT(*) as duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check for null values in required fields
SELECT COUNT(*) as null_names
FROM customers
WHERE name IS NULL;

-- Check for referential integrity
SELECT COUNT(*) as orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

---

# 15. Performance & Optimization

* **EXPLAIN Plan:**

```sql
-- PostgreSQL
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- With execution time
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'john@example.com';
```

* **Query Optimization Tips:**

```sql
-- Use indexes on WHERE, JOIN, and ORDER BY columns
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Avoid SELECT * in production
SELECT name, email FROM users;  -- Instead of SELECT *

-- Use UNION ALL instead of UNION when duplicates are not possible
SELECT name FROM customers UNION ALL SELECT name FROM suppliers;

-- Use EXISTS instead of IN for large datasets
SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.user_id);

-- Use appropriate data types
-- Use VARCHAR instead of TEXT when length is known
-- Use INTEGER instead of VARCHAR for numeric IDs
```

* **Partitioning:**

```sql
-- Create partitioned table (PostgreSQL)
CREATE TABLE sales (
    sale_id SERIAL,
    sale_date DATE,
    customer_id INTEGER,
    amount DECIMAL(10,2)
) PARTITION BY RANGE (sale_date);

-- Create partitions
CREATE TABLE sales_2023 PARTITION OF sales
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE sales_2024 PARTITION OF sales
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

---

# 16. Common Data Engineering Tasks

* **Data Pipeline Monitoring:**

```sql
-- Check table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Monitor long-running queries
SELECT
    pid,
    now() - pg_stat_activity.query_start as duration,
    query
FROM pg_stat_activity
WHERE state = 'active'
AND now() - pg_stat_activity.query_start > interval '1 minute';
```

* **Backup and Recovery:**

```sql
-- PostgreSQL backup
pg_dump -h hostname -U username -d database > backup.sql

-- MySQL backup
mysqldump -h hostname -u username -p database > backup.sql

-- Restore PostgreSQL
psql -h hostname -U username -d database < backup.sql

-- Restore MySQL
mysql -h hostname -u username -p database < backup.sql
```

* **Data Archiving:**

```sql
-- Archive old data
CREATE TABLE orders_archive AS
SELECT * FROM orders
WHERE order_date < '2020-01-01';

-- Remove archived data
DELETE FROM orders WHERE order_date < '2020-01-01';

-- Create partitioned archive
CREATE TABLE orders_archive_2020 PARTITION OF orders_archive
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
```

* **Change Data Capture (CDC):**

```sql
-- Track changes using triggers (PostgreSQL)
CREATE OR REPLACE FUNCTION audit_trigger_function() RETURNS trigger AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, old_values, new_values, changed_at)
    VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

---

# 17. Database-Specific Syntax & Features

* **PostgreSQL-Specific Features:**

```sql
-- JSON operations
SELECT data->>'name' as name FROM json_table;
SELECT data->'address'->>'city' as city FROM json_table;

-- Array operations
SELECT * FROM users WHERE 'admin' = ANY(roles);
SELECT array_agg(name) FROM users;

-- Generate series
SELECT generate_series(1, 10) as numbers;

-- Window functions with frames
SELECT
    date,
    sales,
    SUM(sales) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM daily_sales;

-- Full-text search
SELECT * FROM articles WHERE to_tsvector('english', content) @@ to_tsquery('database & query');
```

* **MySQL-Specific Features:**

```sql
-- Auto-increment
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);

-- LIMIT with OFFSET
SELECT * FROM users LIMIT 10 OFFSET 20;

-- GROUP_CONCAT
SELECT department, GROUP_CONCAT(name SEPARATOR ', ') as employees
FROM staff GROUP BY department;

-- Date functions
SELECT DATE_FORMAT(created_at, '%Y-%m-%d') FROM users;
SELECT DATEDIFF(NOW(), created_at) as days_old FROM users;
```

* **SQL Server-Specific Features:**

```sql
-- TOP clause
SELECT TOP 10 * FROM users ORDER BY created_at DESC;

-- IDENTITY columns
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100)
);

-- PIVOT tables
SELECT * FROM (
    SELECT product, region, sales FROM sales_data
) AS SourceTable
PIVOT (
    SUM(sales) FOR region IN ([North], [South], [East], [West])
) AS PivotTable;

-- Common Table Expressions with recursion
WITH EmployeeHierarchy AS (
    SELECT EmployeeID, ManagerID, Name, 0 as Level
    FROM Employees
    WHERE ManagerID IS NULL

    UNION ALL

    SELECT e.EmployeeID, e.ManagerID, e.Name, eh.Level + 1
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT * FROM EmployeeHierarchy;
```

* **BigQuery-Specific Features:**

```sql
-- ARRAY operations
SELECT name, ARRAY_LENGTH(tags) as tag_count FROM products;

-- STRUCT data types
SELECT STRUCT(name, price) as product_info FROM products;

-- SAFE functions
SELECT SAFE_DIVIDE(numerator, denominator) as safe_ratio FROM calculations;

-- Time travel queries
SELECT * FROM `project.dataset.table` FOR SYSTEM_TIME AS OF TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);

-- Partitioned tables
SELECT * FROM `project.dataset.table`
WHERE DATE(_PARTITIONTIME) BETWEEN '2023-01-01' AND '2023-12-31';
```

---

# 18. Modern SQL Features

* **JSON Operations (PostgreSQL/MySQL/BigQuery):**

```sql
-- Extract values from JSON
SELECT
    id,
    data->>'name' as name,
    data->>'email' as email,
    data->'preferences'->>'theme' as theme
FROM user_profiles;

-- JSON aggregation
SELECT
    user_id,
    json_agg(json_build_object('product_id', product_id, 'quantity', quantity)) as cart_items
FROM cart_items
GROUP BY user_id;

-- JSON path queries
SELECT * FROM events WHERE json_extract_path_text(metadata, 'event_type') = 'purchase';
```

* **Array Operations:**

```sql
-- PostgreSQL arrays
SELECT * FROM articles WHERE 'technology' = ANY(tags);
SELECT array_agg(DISTINCT category) FROM products;

-- BigQuery arrays
SELECT name, ARRAY_LENGTH(split(tags, ',')) as tag_count FROM products;
SELECT name FROM products WHERE 'electronics' IN UNNEST(split(tags, ','));
```

* **Geospatial Queries:**

```sql
-- PostgreSQL PostGIS
SELECT name, ST_Distance(location, ST_Point(-122.4194, 37.7749)::geography) as distance_miles
FROM stores
ORDER BY distance_miles;

-- BigQuery GIS
SELECT name, ST_DISTANCE(location, ST_GEOGPOINT(-122.4194, 37.7749)) as distance_meters
FROM stores;
```

* **Time Series Analysis:**

```sql
-- Time buckets and gaps
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as events_per_hour
FROM events
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour;

-- Moving averages with different window sizes
SELECT
    date,
    sales,
    AVG(sales) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as week_avg,
    AVG(sales) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) as month_avg
FROM daily_sales;
```

---

# 19. Best Practices & Anti-Patterns

* **Query Optimization Best Practices:**

```sql
-- ✅ Good: Use EXISTS for large datasets
SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.user_id);

-- ❌ Bad: Use IN with large subqueries
SELECT * FROM users WHERE user_id IN (SELECT user_id FROM large_orders_table);

-- ✅ Good: Use appropriate indexes
CREATE INDEX idx_orders_user_date ON orders(user_id, order_date);

-- ✅ Good: Avoid SELECT * in production
SELECT id, name, email FROM users;

-- ❌ Bad: SELECT * everywhere
SELECT * FROM users;
```

* **Common Anti-Patterns to Avoid:**

```sql
-- ❌ Anti-pattern: Implicit conversions
SELECT * FROM users WHERE age = '25';  -- String compared to integer

-- ✅ Better: Explicit types
SELECT * FROM users WHERE age = 25;

-- ❌ Anti-pattern: Non-SARGable queries
SELECT * FROM users WHERE YEAR(created_at) = 2023;

-- ✅ Better: SARGable queries
SELECT * FROM users WHERE created_at >= '2023-01-01' AND created_at < '2024-01-01';

-- ❌ Anti-pattern: Nested views
CREATE VIEW v1 AS SELECT * FROM table1;
CREATE VIEW v2 AS SELECT * FROM v1 WHERE condition1;
CREATE VIEW v3 AS SELECT * FROM v2 WHERE condition2;

-- ✅ Better: Flatten or use CTEs
CREATE VIEW efficient_view AS
SELECT * FROM table1 WHERE condition1 AND condition2;
```

* **Security Best Practices:**

```sql
-- ✅ Use parameterized queries to prevent SQL injection
PREPARE user_query (text, text) AS
    SELECT * FROM users WHERE name = $1 AND email = $2;

EXECUTE user_query('John Doe', 'john@example.com');

-- ✅ Use proper permissions
GRANT SELECT ON users TO readonly_user;
REVOKE INSERT, UPDATE, DELETE ON sensitive_table FROM public;

-- ✅ Audit sensitive operations
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    operation TEXT,
    user_id INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB
);
```

---

# 20. Real-World Case Studies

* **E-commerce Analytics Dashboard:**

```sql
-- Customer lifetime value calculation
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) as order_count,
        SUM(total) as total_spent,
        MIN(order_date) as first_order,
        MAX(order_date) as last_order
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.name,
    co.order_count,
    co.total_spent,
    co.total_spent / NULLIF(co.order_count, 0) as avg_order_value,
    EXTRACT(DAY FROM co.last_order - co.first_order) as customer_age_days
FROM customers c
LEFT JOIN customer_orders co ON c.customer_id = co.customer_id
ORDER BY co.total_spent DESC NULLS LAST;

-- Product performance analysis
SELECT
    p.category,
    p.name,
    SUM(oi.quantity) as total_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price,
    COUNT(DISTINCT o.customer_id) as unique_customers
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.category, p.name
ORDER BY total_revenue DESC;
```

* **Financial Reporting Queries:**

```sql
-- Monthly revenue report with year-over-year comparison
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) as month,
        EXTRACT(YEAR FROM order_date) as year,
        SUM(total) as revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE_TRUNC('month', order_date), EXTRACT(YEAR FROM order_date)
)
SELECT
    m1.month,
    m1.year,
    m1.revenue as current_year_revenue,
    m2.revenue as previous_year_revenue,
    CASE
        WHEN m2.revenue > 0 THEN ((m1.revenue - m2.revenue) / m2.revenue) * 100
        ELSE NULL
    END as yoy_growth_percent
FROM monthly_revenue m1
LEFT JOIN monthly_revenue m2 ON m1.month = m2.month AND m1.year = m2.year + 1
ORDER BY m1.year, m1.month;

-- Customer segmentation
SELECT
    customer_id,
    name,
    total_spent,
    order_count,
    CASE
        WHEN total_spent > 1000 AND order_count > 10 THEN 'VIP'
        WHEN total_spent > 500 OR order_count > 5 THEN 'Regular'
        WHEN total_spent > 0 THEN 'New'
        ELSE 'Inactive'
    END as customer_segment
FROM (
    SELECT
        c.customer_id,
        c.name,
        COALESCE(SUM(o.total), 0) as total_spent,
        COUNT(o.order_id) as order_count
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
) customer_summary;
```

* **IoT Data Processing:**

```sql
-- Sensor data aggregation with quality checks
SELECT
    sensor_id,
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as reading_count,
    AVG(temperature) as avg_temp,
    MIN(temperature) as min_temp,
    MAX(temperature) as max_temp,
    STDDEV(temperature) as temp_stddev,
    -- Quality check: flag suspicious readings
    CASE
        WHEN MAX(temperature) - MIN(temperature) > 50 THEN 'Suspicious Range'
        WHEN COUNT(*) < 30 THEN 'Low Reading Count'
        ELSE 'Normal'
    END as quality_flag
FROM sensor_readings
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY sensor_id, DATE_TRUNC('hour', timestamp)
ORDER BY sensor_id, hour;

-- Predictive maintenance alerts
WITH equipment_metrics AS (
    SELECT
        equipment_id,
        metric_name,
        AVG(value) as avg_value,
        STDDEV(value) as stddev_value,
        MAX(timestamp) as last_reading
    FROM equipment_sensors
    WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY equipment_id, metric_name
)
SELECT
    em.equipment_id,
    em.metric_name,
    em.avg_value,
    em.stddev_value,
    CASE
        WHEN em.avg_value > (baseline.avg_value + 2 * baseline.stddev_value) THEN 'High Alert'
        WHEN em.avg_value > (baseline.avg_value + baseline.stddev_value) THEN 'Warning'
        ELSE 'Normal'
    END as alert_level
FROM equipment_metrics em
JOIN baseline_metrics baseline USING (equipment_id, metric_name)
WHERE em.last_reading >= CURRENT_DATE - INTERVAL '1 day';
```

---

# 21. Setting Up SQL Environment Locally

* **Setting up a local SQL environment** is essential for practicing SQL commands, testing queries, and building database skills without affecting production systems.

## SQLite (Lightweight, File-Based Database)

* **Best for:** Learning basics, small projects, embedded applications
* **No server required:** Database stored in a single file

### Installation:

**Windows:**
```bash
# Download from: https://www.sqlite.org/download.html
# Or use Chocolatey:
choco install sqlite
```

**macOS:**
```bash
# Using Homebrew
brew install sqlite3

# Or download from: https://www.sqlite.org/download.html
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install sqlite3
```

### Getting Started with SQLite:

```bash
# Create a new database
sqlite3 practice.db

# You'll see the SQLite prompt:
# sqlite>

# Create tables and practice
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    age INTEGER
);

# Insert sample data
INSERT INTO users (name, email, age) VALUES
('John Doe', 'john@example.com', 30),
('Jane Smith', 'jane@example.com', 25);

# Run queries
SELECT * FROM users;
SELECT name, age FROM users WHERE age > 25;

# Exit SQLite
.quit
```

### SQLite GUI Tools:
- **DB Browser for SQLite** (Free, Cross-platform)
- **SQLiteStudio** (Free, Cross-platform)
- **DBeaver** (Free, Supports multiple databases)

## PostgreSQL (Advanced, Production-Ready)

* **Best for:** Professional development, complex queries, production applications
* **Features:** ACID compliance, advanced data types, extensions

### Installation:

**Windows:**
```bash
# Download from: https://www.postgresql.org/download/windows/
# Or use Chocolatey:
choco install postgresql
```

**macOS:**
```bash
# Using Homebrew
brew install postgresql
brew services start postgresql

# Or download from: https://www.postgresql.org/download/macosx/
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### PostgreSQL Setup:

```bash
# Switch to postgres user
sudo -u postgres psql

# Or on macOS/Windows with brew:
psql postgres

# Create a database
CREATE DATABASE sql_practice;

# Create a user (optional)
CREATE USER sql_user WITH PASSWORD 'password123';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE sql_practice TO sql_user;

# Exit
\q
```

### Connect and Practice:

```bash
# Connect to your database
psql -d sql_practice

# Or with user credentials
psql -d sql_practice -U sql_user -h localhost

# Create the sample schema from section 2
\i create_sample_schema.sql

# Run queries
SELECT * FROM users;
SELECT COUNT(*) FROM orders;
```

### PostgreSQL GUI Tools:
- **pgAdmin** (Official, Free)
- **DBeaver** (Free, Multi-database)
- **DataGrip** (JetBrains, Paid)

## MySQL (Popular, Web Applications)

* **Best for:** Web development, LAMP stack, high-performance applications

### Installation:

**Windows:**
```bash
# Download from: https://dev.mysql.com/downloads/mysql/
# Or use Chocolatey:
choco install mysql
```

**macOS:**
```bash
# Using Homebrew
brew install mysql
brew services start mysql

# Secure installation
mysql_secure_installation
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure installation
sudo mysql_secure_installation
```

### MySQL Setup:

```bash
# Connect as root
mysql -u root -p

# Create database
CREATE DATABASE sql_practice;

# Create user
CREATE USER 'sql_user'@'localhost' IDENTIFIED BY 'password123';

# Grant privileges
GRANT ALL PRIVILEGES ON sql_practice.* TO 'sql_user'@'localhost';

# Flush privileges
FLUSH PRIVILEGES;

# Exit
EXIT;
```

### Connect and Practice:

```bash
# Connect with user
mysql -u sql_user -p sql_practice

# Create tables (note: use backticks for column names if needed)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INT,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# Run queries
SELECT * FROM users LIMIT 10;
DESCRIBE users;
```

### MySQL GUI Tools:
- **MySQL Workbench** (Official, Free)
- **phpMyAdmin** (Web-based, Free)
- **DBeaver** (Free, Multi-database)

## Docker Setup (Cross-Platform)

* **Best for:** Consistent environments, easy cleanup, multiple database versions

### PostgreSQL with Docker:

```bash
# Pull PostgreSQL image
docker pull postgres:15

# Run PostgreSQL container
docker run --name postgres-practice \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=sql_practice \
  -e POSTGRES_USER=sql_user \
  -p 5432:5432 \
  -d postgres:15

# Connect from host
psql -h localhost -p 5432 -U sql_user -d sql_practice
```

### MySQL with Docker:

```bash
# Pull MySQL image
docker pull mysql:8.0

# Run MySQL container
docker run --name mysql-practice \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=sql_practice \
  -e MYSQL_USER=sql_user \
  -e MYSQL_PASSWORD=password123 \
  -p 3306:3306 \
  -d mysql:8.0

# Connect from host
mysql -h localhost -P 3306 -u sql_user -p sql_practice
```

## Sample Practice Database Setup

### Download Sample Databases:

**PostgreSQL Sample Databases:**
- **Pagila** (DVD rental database): https://github.com/devrimgunduz/pagila
- **DVD Rental**: Similar to Sakila but for PostgreSQL

**MySQL Sample Databases:**
- **Sakila** (DVD rental database): https://dev.mysql.com/doc/sakila/en/
- **World** database: https://dev.mysql.com/doc/world-setup/en/

### Quick Setup Script:

```sql
-- Create sample database schema (PostgreSQL/MySQL compatible)
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    salary DECIMAL(10,2),
    hire_date DATE
);

-- Insert sample data
INSERT INTO departments (dept_name) VALUES
('Engineering'), ('Sales'), ('Marketing'), ('HR');

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date) VALUES
('John', 'Doe', 1, 75000, '2023-01-15'),
('Jane', 'Smith', 2, 65000, '2023-02-20'),
('Bob', 'Johnson', 1, 80000, '2022-11-10'),
('Alice', 'Williams', 3, 55000, '2023-03-05');
```

## Online SQL Practice Platforms

* **SQLZoo:** Interactive SQL learning with immediate feedback
* **LeetCode SQL:** Practice with real interview questions
* **HackerRank SQL:** Coding challenges and skill assessment
* **Mode Analytics SQL Tutorial:** Free interactive SQL course
* **SQL Fiddle:** Online SQL editor for quick testing

## Best Practices for Local Setup

1. **Use version control** for your SQL scripts
2. **Create separate databases** for different projects
3. **Backup regularly** when working with important data
4. **Use meaningful names** for databases and tables
5. **Document your schema** with comments
6. **Test queries** in a safe environment before production

## Troubleshooting Common Issues

**PostgreSQL:**
```bash
# Check if service is running
sudo systemctl status postgresql

# Restart service
sudo systemctl restart postgresql

# Check logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

**MySQL:**
```bash
# Check if service is running
sudo systemctl status mysql

# Restart service
sudo systemctl restart mysql

# Check logs
sudo tail -f /var/log/mysql/error.log
```

**Connection Issues:**
- Verify host and port
- Check firewall settings
- Ensure user has proper permissions
- Confirm database exists

---

# Quick Reference: Essential Commands

```sql
-- Database connection
-- PostgreSQL: psql -h host -d db -U user
-- MySQL: mysql -h host -u user -p db

-- Show databases/tables
SHOW DATABASES;  -- MySQL
SELECT datname FROM pg_database;  -- PostgreSQL
SHOW TABLES;  -- MySQL
\dt  -- PostgreSQL

-- Describe table structure
DESCRIBE table_name;  -- MySQL
\d table_name  -- PostgreSQL

-- Get current date/time
SELECT CURRENT_DATE, CURRENT_TIME, CURRENT_TIMESTAMP;

-- String functions
SELECT UPPER(name), LOWER(email), LENGTH(name) FROM users;

-- Date functions
SELECT EXTRACT(YEAR FROM order_date), DATE_TRUNC('month', order_date) FROM orders;

-- Export query results
-- PostgreSQL: \COPY (SELECT * FROM users) TO 'users.csv' WITH CSV HEADER
-- MySQL: SELECT * FROM users INTO OUTFILE 'users.csv' FIELDS TERMINATED BY ',';

-- Transaction control
BEGIN;
COMMIT;
ROLLBACK;
```

---

*End of SQL cheat sheet — master data engineering with SQL!*
