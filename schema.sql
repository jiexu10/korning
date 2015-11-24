-- DEFINE YOUR DATABASE SCHEMA HERE

DROP TABLE IF EXISTS employees, customers, products, invoice_freq, sales_info, sales_join_table;

CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL,
  name VARCHAR(255)
);

CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  account_no TEXT NOT NULL,
  name VARCHAR(255)
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE invoice_freq (
  id SERIAL PRIMARY KEY,
  frequency VARCHAR(255) NOT NULL
);

CREATE TABLE sales_info (
  id SERIAL PRIMARY KEY,
  invoice_no INTEGER NOT NULL,
  sale_date DATE,
  sale_amount REAL,
  units_sold INTEGER,
  employee_id INTEGER REFERENCES employees (id),
  customer_id INTEGER REFERENCES customers (id),
  product_id INTEGER REFERENCES products (id),
  frequency_id INTEGER REFERENCES invoice_freq (id)
);
