CREATE DATABASE monday_coffee_db;

USE monday_coffee_db;

CREATE TABLE city (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(45),
    population BIGINT,
    estimated_rent FLOAT,
    city_rank INT
    );


CREATE TABLE `monday_coffee_db`.`customers` (
  `customers_id` INT NOT NULL,
  `customer_name` VARCHAR(45) NULL,
  `city_id` INT NULL,
  INDEX `city_id_idx` (`city_id` ASC) VISIBLE,
  CONSTRAINT `fk_city`
    FOREIGN KEY (`city_id`) 
    REFERENCES `monday_coffee_db`.`city` (`city_id`) 
    );
    
    
CREATE TABLE `monday_coffee_db`.`products` (
  `product_id` INT NOT NULL,
  `product_name` VARCHAR(45) NULL,
  `price` FLOAT NULL,
  PRIMARY KEY (`product_id`));
  
CREATE TABLE `monday_coffee_db`.`sales` (
  `sale_id` INT NOT NULL,
  `sale_date` DATE NULL,
  `product_id` INT NULL,
  `customers_id` INT NULL,
  `total` FLOAT NULL,
  `rating` INT NULL,
  PRIMARY KEY (`sale_id`),
  INDEX `fk_products_idx` (`product_id` ASC) VISIBLE,
  INDEX `fk_customers_idx` (`customers_id` ASC) VISIBLE,
  CONSTRAINT `fk_products`
    FOREIGN KEY (`product_id`)
    REFERENCES `monday_coffee_db`.`products` (`product_id`),
  CONSTRAINT `fk_customers`
    FOREIGN KEY (`customers_id`)
    REFERENCES `monday_coffee_db`.`customers` (`customers_id`)
      );

--- Monday Coffee Data Anlaysis;

SELECT *
FROM city;

SELECT *
FROM customers;

SELECT *
FROM products;

SELECT *
FROM sales;

--- Reports and Data Analysis;

-- Task 1: Coffee Consumers Count 
-- How many people in each city are estimated to consume coffee, given that 25% of the population does? ;

SELECT city_name,
       population * 0.25,
       city_rank
FROM city
ORDER BY population DESC ;

--- Task 2: Total Revenue from Coffee Sales
--- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023? ;

SELECT
     SUM(total) as total_revenue
FROM sales
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31' ;

--- Task 3: Sales Count for Each Product
--- How many units of each coffee product have been sold? ;

SELECT 
     p.product_name,
     COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN sales as s
ON s.product_id = p.product_id
GROUP BY 1 ;

--- Task 4: Average Sales Amount per City;
--- What is the average sales amount per customer in each city? ;

SELECT 
      c.city_name,
      SUM(s.total) AS total_sale,
      COUNT(DISTINCT s.customers_id) as total_customers,
      ROUND(SUM(s.total) / COUNT(DISTINCT s.customers_id),2) as avg_sale_per_customer
FROM city as c
JOIN customers as cst
ON c.city_id = cst.city_id
LEFT JOIN sales as s
ON cst.customers_id = s.customers_id
GROUP BY 1
ORDER BY 2 DESC;

--- Task 5: City Population and Coffee Consumers
--- Provide a list of cities along with their populations and estimated coffee consumers.;

SELECT 
      c.city_name,
      c.population,
      COUNT(DISTINCT cst.customers_id) as unique_customers_per_city
FROM city as c
JOIN customers as cst
ON c.city_id = cst.city_id
GROUP BY 1,2 ;

--- Task 6: Top Selling Products by City
--- What are the top 3 selling products in each city based on sales volume?;

CREATE TABLE products_rank
AS
SELECT 
      c.city_name,
      p.product_name,
      COUNT(s.sale_id) as total_orders,
      RANK() OVER (PARTITION BY c.city_name ORDER BY COUNT(s.sale_id) DESC)
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as cst
ON cst.customers_id = s.customers_id
JOIN city as c
ON c.city_id = cst.city_id
GROUP BY 1,2 ;

-- Task 7:Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products? ;

SELECT 
      c.city_name,
      COUNT(DISTINCT cst.customers_id) as unique_customers_per_city,
      COUNT(s.product_id) as product_count_ordered
FROM city as c
LEFT JOIN customers as cst
ON c.city_id = cst.city_id
JOIN sales as s
ON s.customers_id = cst.customers_id
WHERE s.product_id <= 14
GROUP BY 1;

-- Task 8: Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer ;


SELECT 
      c.city_name,
      c.estimated_rent,
      SUM(s.total) AS total_sale,
      COUNT(DISTINCT s.customers_id) as total_customers,
      ROUND(SUM(s.total) / COUNT(DISTINCT s.customers_id),2) as avg_sale_per_customer,
      ROUND(c.estimated_rent / COUNT(DISTINCT cst.customers_id),2) as avg_rent
FROM city as c
JOIN customers as cst
ON c.city_id = cst.city_id
JOIN sales as s
ON cst.customers_id = s.customers_id
GROUP BY 1,2
ORDER BY 5 DESC ;

-- Task 9: Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly);

WITH monthly_sales
AS 
(
SELECT 
     c.city_name,
     YEAR(sale_date) as year,
     MONTH(sale_date) as month,
     SUM(s.total) as total_sale
FROM sales as s
JOIN customers as cst
ON cst.customers_id = s.customers_id
JOIN city as c
ON c.city_id = cst.city_id
GROUP BY 1,2,3 
ORDER BY 1, 2, 3
),
growth_ratio
AS 
(
SELECT
      city_name,
      month,
      year,
      total_sale as current_month_sale,
      LAG(total_sale,1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
FROM monthly_sales
)
SELECT
     city_name,
     month,
     year,
     current_month_sale,
     last_month_sale,
    ROUND((current_month_sale - last_month_sale)/last_month_sale * 100,2) as growth_ratio
FROM growth_ratio 
WHERE last_month_sale IS NOT NULL ;
     

---- Task 10: Market Potential Analysis
--- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer considering 25% of the population consumes coffee;

SELECT 
      c.city_name,
      c.estimated_rent,
      SUM(s.total) AS total_sale,
      COUNT(DISTINCT s.customers_id) as total_customers,
      ROUND(SUM(s.total) / COUNT(DISTINCT s.customers_id),2) as avg_sale_per_customer,
      ROUND(c.estimated_rent / COUNT(DISTINCT cst.customers_id),2) as avg_rent,
      ROUND(c.population / 1000000.0,2) as population_in_millions,
      ROUND((c.population * 0.25) / 1000000.0 , 2) as est_coffee_consumers_in_millions
FROM city as c
JOIN customers as cst
ON c.city_id = cst.city_id
JOIN sales as s
ON cst.customers_id = s.customers_id
GROUP BY 1,2,7,8
ORDER BY 3 DESC;

--- Recommendations 


-- 1) DELHI - Highest Potential in Sales
            --highest estimated coffee consumer which is 7.7 million
            -highest total per customer which is 68
            -average rent per customer is low (under 500)
-- 2) Pune- Expected to have decent potential with the highest Profitability due to lower costs
          -highest total_sale
          -average sale per customer is also high
          -average rent per customer is very Low
-- 3) Chennai- Offers a balance of high potential and affordable rent


---- END OF PROJECT.









































































  
  
  