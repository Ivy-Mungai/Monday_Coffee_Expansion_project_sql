# Monday Coffee Expansion SQL Project


## Objective
The goal of this project is to analyze the sales data of Monday Coffee, a company that has been selling its products online since January 2023, and to recommend the top three major cities in India for opening new coffee shop locations based on consumer demand and sales performance.

## Key Questions
1. **Coffee Consumers Count**  
   How many people in each city are estimated to consume coffee, given that 25% of the population does?

```sql
SELECT city_name,
       population * 0.25,
       city_rank
FROM city
ORDER BY population DESC
```

2. **Total Revenue from Coffee Sales**  
   What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

   ```sql
   
   SELECT
     SUM(total) as total_revenue
FROM sales
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31'

``

3. **Sales Count for Each Product**  
   How many units of each coffee product have been sold?

```sql
SELECT 
     p.product_name,
     COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN sales as s
ON s.product_id = p.product_id
GROUP BY 1

```

4. **Average Sales Amount per City**  
   What is the average sales amount per customer in each city?

   ```sql
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

``

5. **City Population and Coffee Consumers**  
   Provide a list of cities along with their populations and estimated coffee consumers.

```sql
SELECT 
      c.city_name,
      c.population,
      COUNT(DISTINCT cst.customers_id) as unique_customers_per_city
FROM city as c
JOIN customers as cst
ON c.city_id = cst.city_id
GROUP BY 1,2 ;

```

6. **Top Selling Products by City**  
   What are the top 3 selling products in each city based on sales volume?

   ```sql
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

``

7. **Customer Segmentation by City**  
   How many unique customers are there in each city who have purchased coffee products?

   ```sql
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

``

8. **Average Sale vs Rent**  
   Find each city and their average sale per customer and avg rent per customer

   ```sql
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
ORDER BY 5 DESC;

``

9. **Monthly Sales Growth**  
   Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

   ```sql

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

``

10. **Market Potential Analysis**  
    Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated  coffee consumer

    ```sql
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

``
    

## Recommendations
After analyzing the data, the recommended top three cities for new store openings are:

**City 1: Pune**  
1. Average rent per customer is very low.  
2. Highest total revenue.  
3. Average sales per customer is also high.
4. Expected to have decent potential with the highest profitability

**City 2: Delhi**  
1. Highest estimated coffee consumers at 7.7 million.  
2. Highest total number of customers, which is 68.  
3. Average rent per customer is 330 (still under 500).
4. Highest Potentila in sales
   
**City 3: Chennai** 
1. Offers a balance of high potential ad affordable rent 
2. Average rent per customer is very low at 156.  
3. Average sales per customer is better at 11.6k.

---
