SELECT * FROM public.dim_product;
SELECT * FROM public.dim_store;
SELECT * FROM public.dim_time;
SELECT * FROM public.dim_sales_name;

-- Insert product_sales data into data mart
CREATE TABLE dm.dm_product_sales AS
SELECT 
	fs.product_id, 
	dp.product_name, 
	dp.category AS product_category, 
	dt.date AS sales_date, 
	dt.day_of_week, 
	SUM(fs.quantity * fs.price) AS total_product_sales,
	SUM(fs.quantity) AS total_quantity_sold
FROM public.fact_sales AS "fs"
INNER JOIN public.dim_product AS dp
ON fs.product_id = dp.product_id
INNER JOIN public.dim_time AS dt
ON fs.time_id = dt.time_id
GROUP BY 1,2,3,4,5;

-- Insert product_sales_per_location data into data mart
CREATE TABLE dm.dm_sales_per_location AS 
SELECT 
	fs.store_id, 
	ds.store_name,
	ds.city,
	ds.state,
	dt.date AS sales_date, 
	dt.day_of_week,
	SUM(fs.quantity * fs.price) AS total_sales,
	SUM(fs.quantity) AS total_quantity_sold
FROM public.fact_sales AS "fs"
INNER JOIN public.dim_store AS ds
ON fs.store_id = ds.store_id
INNER JOIN public.dim_time AS dt
ON fs.time_id = dt.time_id
GROUP BY 1,2,3,4,5,6;

-- Insert sales_performance data into data mart
CREATE TABLE dm.dm_sales_performance AS
SELECT
	fs.sales_name_id,
	dsn.sales_name,
	dt.date AS sales_date, 
	dt.day_of_week,
	SUM(fs.quantity * fs.price) AS total_sales,
	SUM(fs.quantity) AS total_quantity_sold
FROM public.fact_sales AS "fs"
INNER JOIN public.dim_sales_name AS dsn
ON fs.sales_name_id = dsn.sales_name_id
INNER JOIN public.dim_time AS dt
ON fs.time_id = dt.time_id
GROUP BY 1,2,3,4;

-- menambahkan kolom data historis
ALTER TABLE dm.dm_product_sales
ADD COLUMN last_update TIMESTAMP;

ALTER TABLE dm.dm_sales_per_location
ADD COLUMN last_update TIMESTAMP;

ALTER TABLE dm.dm_sales_performance
ADD COLUMN last_update TIMESTAMP;

-- Pembaruan data untuk baris yang tersedia
UPDATE dm.dm_product_sales SET last_update = '2024-01-01';
UPDATE dm.dm_sales_per_location SET last_update = '2024-01-01';
UPDATE dm.dm_sales_performance SET last_update = '2024-01-01';

-- Menampilkan revenue terbanyak tiap kategori

(SELECT DISTINCT product_name, product_category, SUM(total_product_sales) AS total_sales
FROM dm.dm_product_sales
WHERE product_category = 'Coffee'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1)
UNION
(SELECT DISTINCT product_name, product_category, SUM(total_product_sales) AS total_sales
FROM dm.dm_product_sales
WHERE product_category = 'Bakery'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1)
UNION
(SELECT DISTINCT product_name, product_category, SUM(total_product_sales) AS total_sales
FROM dm.dm_product_sales
WHERE product_category = 'Tea'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1)
ORDER BY 3 DESC;

-- menampilkan toko dengan penjualan tertinggi
SELECT store_name, city, SUM(total_sales) AS total_sales
FROM dm.dm_sales_per_location
GROUP BY 1,2
ORDER BY 3 DESC;

-- menampilkan karyawan sales dengan penjualan tertinggi
SELECT sales_name_id, sales_name, SUM(total_sales) AS total_sales
FROM dm.dm_sales_performance
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;