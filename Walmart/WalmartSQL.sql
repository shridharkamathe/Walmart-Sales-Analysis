CREATE DATABASE IF NOT EXISTS walmartSales;


CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12, 4),
    rating FLOAT
);


SELECT
	*
FROM sales;


-- --------------FEATURE ENGINEERING----------------
SELECT
	time,
	(CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END) AS time_of_day
FROM sales;


ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

UPDATE sales
SET time_of_day = (
	CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
);


-- Adding day_name column
SELECT
	date,
	DAYNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(date);


-- Adding month_name column
SELECT
	date,
	MONTHNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(date);

-- --------------------------------------------------------------------
-- ---------------------------- Generic ------------------------------
-- --------------------------------------------------------------------

-- How many unique cities does the data have?
SELECT 
	DISTINCT city
FROM sales;

-- In which city is each branch?
SELECT 
	DISTINCT city,
    branch
FROM sales;


-- --------------------------------------------------------------------
-- ---------------------------- Product -------------------------------
-- --------------------------------------------------------------------

-- How many unique product lines does the data have?
SELECT
    DISTINCT product_line,
    ROW_NUMBER() OVER (ORDER BY product_line) AS row_num
FROM
    sales
GROUP BY 1;


-- What is the most selling product line
SELECT
	SUM(quantity) as qty,
    product_line
FROM sales
GROUP BY product_line
ORDER BY qty DESC;

-- What is the total revenue by month
SELECT
	month_name AS month,
	SUM(total) AS total_revenue
FROM sales
GROUP BY month_name 
ORDER BY total_revenue;


-- What month had the largest COGS?
SELECT
	month_name AS month,
	SUM(cogs) AS cogs
FROM sales
GROUP BY month_name 
ORDER BY cogs DESC;


-- What product line had the largest revenue?
SELECT
	product_line,
	SUM(total) as total_revenue
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC;

-- What is the city with the largest revenue?
SELECT
	branch,
	city,
	SUM(total) AS total_revenue
FROM sales
GROUP BY city, branch 
ORDER BY total_revenue DESC;


-- What product line had the largest VAT?
SELECT
	product_line,
	ROUND(AVG(tax_pct),2) as avg_tax
FROM sales
GROUP BY product_line
ORDER BY avg_tax DESC;


-- Fetch each product line and add a column to those product 
-- line showing "Good", "Bad". Good if its greater than average sales
SELECT 
	AVG(quantity) AS avg_qnty
FROM Wsales;

SELECT
	product_line,
	CASE
		WHEN AVG(quantity) > 5.52 THEN "Good"
        ELSE "Bad"
    END AS remark
FROM Wsales
GROUP BY product_line;


-- Which branch sold more products than average product sold?
SELECT 
	branch,
    SUM(quantity) AS qnty
FROM Wsales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM Wsales);


-- What is the most common product line by gender
SELECT
	gender,
    product_line,
    COUNT(gender) AS total_cnt
FROM Wsales
GROUP BY gender, product_line
ORDER BY total_cnt DESC;

-- What is the average rating of each product line
SELECT
	ROUND(AVG(rating), 2) as avg_rating,
    product_line
FROM Wsales
GROUP BY product_line
ORDER BY avg_rating DESC;


-- -------------------------- Customers -------------------------------


-- How many unique customer types does the data have?
SELECT
	DISTINCT customer_type
FROM Wsales;

-- How many unique payment methods does the data have?
SELECT
	DISTINCT payment
FROM Wsales;


-- What is the most common customer type?
SELECT
	customer_type,
	count(customer_type) as count
FROM Wsales
GROUP BY customer_type
ORDER BY count DESC;

-- Which customer type buys the most?
SELECT
	customer_type,
    COUNT(invoice_id) as count
FROM Wsales
GROUP BY customer_type
ORDER BY count DESC;


-- What is the gender of most of the customers?
SELECT
	gender,
	COUNT(*) as gender_cnt
FROM Wsales
GROUP BY gender
ORDER BY gender_cnt DESC;

-- What is the gender distribution per branch?
SELECT
	gender,
	COUNT(*) as gender_cnt
FROM Wsales
WHERE branch = "C"
GROUP BY gender
ORDER BY gender_cnt DESC;
-- Gender per branch is more or less the same hence, I don't think has
-- an effect of the sales per branch and other factors.

-- Which time of the day do customers give most ratings?
SELECT
	time_of_day,
	ROUND(AVG(rating),2) as avg_rating
FROM Wsales
GROUP BY time_of_day
ORDER BY avg_rating DESC;
-- Looks like time of the day does not really affect the rating, its
-- more or less the same rating each time of the day.alter


-- Which time of the day do customers give most ratings per branch?
SELECT
	branch,
    time_of_day
FROM (
	SELECT
		branch,
		time_of_day,
		COUNT(rating) AS ratings_count,
		RANK() OVER (PARTITION BY branch ORDER BY COUNT(rating) DESC) AS rank_
	FROM
		Wsales
	GROUP BY
		branch, time_of_day
	ORDER BY
		branch, ratings_count DESC) AS subquery
WHERE rank_ = 1;

-- Which day of the week has the best average ratings per branch?

SELECT
	branch,
    day_name,
    average_rating
    FROM (
		SELECT 
			branch,
			day_name,
			ROUND(AVG(rating),2) AS average_rating,
			RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as average_ratings
		FROM 
			sales
		GROUP BY 
			branch, day_name
		ORDER BY 
			branch, average_ratings) AS subquery1
WHERE average_ratings = 1;


-- --------------------------------------------------------------------
-- --------------------------------------------------------------------

-- --------------------------------------------------------------------
-- ---------------------------- Sales ---------------------------------
-- --------------------------------------------------------------------

-- Number of sales made in each time of the day per weekday 
SELECT
    day_name,
    MAX(CASE WHEN time_of_day = 'Morning' THEN total_sales END) AS Morning,
    MAX(CASE WHEN time_of_day = 'Afternoon' THEN total_sales END) AS Afternoon,
    MAX(CASE WHEN time_of_day = 'Evening' THEN total_sales END) AS Evening
FROM (
    SELECT
        day_name,
        time_of_day,
        COUNT(*) OVER(PARTITION BY day_name, time_of_day) AS total_sales
    FROM
        sales
) AS subquery
GROUP BY
    day_name
ORDER BY
    day_name;


-- Which of the customer types brings the most revenue?
SELECT
	customer_type,
	ROUND(SUM(total),2) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- Which city has the largest tax/VAT percent?
SELECT
	city,
    ROUND(AVG(tax_pct), 2) AS avg_tax_pct
FROM sales
GROUP BY city 
ORDER BY avg_tax_pct DESC;

-- Which customer type pays the most in VAT?
SELECT
	customer_type,
	SUM(tax_pct) as total_tax
FROM sales
GROUP BY customer_type
ORDER BY total_tax DESC;

-- --------------------------------------------------------------------
-- --------------------------------------------------------------------
