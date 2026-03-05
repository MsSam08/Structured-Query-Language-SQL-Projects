# Monday Coffee - Expansion Analysis | SQL Project

![Database](https://github.com/MsSam08/Structured-Query-Language-SQL-Projects/blob/main/Monday%20Coffee%20Business%20Expansion%20project/1.png)
## About This Project

Monday Coffee is a fictional coffee brand that has been selling its products online across multiple Indian cities since January 2023. In this project, I used SQL to analyse their sales data and identify the top three cities in India best suited for opening new physical coffee shop locations.

The analysis looks at consumer demand, revenue performance, customer behaviour, and operational costs (rent) to make data-driven expansion recommendations.

---

## Objectives

1. **Estimate coffee consumer demand** across cities based on population data.
2. **Analyse revenue and sales performance** by city, product, and time period.
3. **Evaluate cost efficiency** by comparing average sales per customer against average rent per customer.
4. **Track sales growth trends** using month-on-month percentage change.
5. **Identify the top three cities** for new store openings based on a combination of revenue, customer base, and market potential.

---

## Database Tables

| Table | Description |
|-------|-------------|
| `city` | City-level data including population, estimated rent, and city rank |
| `products` | Coffee product catalogue |
| `customers` | Customer records linked to their city |
| `sales` | Transaction-level sales data including product, customer, date, and total |

---
## Database Setup

![Database](https://github.com/MsSam08/Structured-Query-Language-SQL-Projects/blob/main/Monday%20Coffee%20Business%20Expansion%20project/schema.png)

## Questions & SQL Solutions

### Q1. Coffee Consumers Count
**How many people in each city are estimated to consume coffee, assuming 25% of the population does?**

```sql
SELECT
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;
```

---

### Q2. Total Revenue from Coffee Sales
**What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?**

```sql
SELECT
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci     ON ci.city_id = c.city_id
WHERE EXTRACT(YEAR    FROM s.sale_date) = 2023
  AND EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;
```

---

### Q3. Sales Count for Each Product
**How many units of each coffee product have been sold?**

```sql
SELECT
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products AS p
LEFT JOIN sales AS s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;
```

---

### Q4. Average Sales Amount per City
**What is the average sales amount per customer in each city?**

```sql
SELECT
    ci.city_name,
    SUM(s.total)                    AS total_revenue,
    COUNT(DISTINCT s.customer_id)   AS total_customers,
    ROUND(
        SUM(s.total)::numeric /
        COUNT(DISTINCT s.customer_id)::numeric
    , 2) AS avg_sale_per_customer
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci     ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;
```

---

### Q5. City Population and Estimated Coffee Consumers
**List each city with its total current customers and estimated coffee-drinking population.**

```sql
WITH city_table AS (
    SELECT
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_in_millions
    FROM city
),
customers_table AS (
    SELECT
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci     ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT
    ct.city_name,
    ct.coffee_consumers_in_millions,
    cust.unique_customers
FROM city_table AS ct
JOIN customers_table AS cust ON ct.city_name = cust.city_name;
```

---

### Q6. Top 3 Selling Products by City
**What are the top 3 selling products in each city based on sales volume?**

```sql
SELECT *
FROM (
    SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER(
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rank
    FROM sales AS s
    JOIN products AS p  ON s.product_id = p.product_id
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci     ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) AS ranked
WHERE rank <= 3;
```

---

### Q7. Unique Customers per City
**How many unique customers in each city have purchased coffee products?**

```sql
SELECT
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city AS ci
LEFT JOIN customers AS c ON c.city_id = ci.city_id
JOIN sales AS s          ON s.customer_id = c.customer_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY ci.city_name
ORDER BY unique_customers DESC;
```

---

### Q8. Average Sale vs Average Rent per Customer
**Compare each city's average sale per customer against its average rent per customer.**

```sql
WITH city_sales AS (
    SELECT
        ci.city_name,
        SUM(s.total)                  AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total)::numeric /
            COUNT(DISTINCT s.customer_id)::numeric
        , 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci     ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name, estimated_rent
    FROM city
)
SELECT
    cr.city_name,
    cr.estimated_rent,
    cs.total_customers,
    cs.avg_sale_per_customer,
    ROUND(
        cr.estimated_rent::numeric /
        cs.total_customers::numeric
    , 2) AS avg_rent_per_customer
FROM city_rent AS cr
JOIN city_sales AS cs ON cr.city_name = cs.city_name
ORDER BY cs.avg_sale_per_customer DESC;
```

---

### Q9. Monthly Sales Growth Rate
**What is the month-on-month percentage growth or decline in sales for each city?**

```sql
WITH monthly_sales AS (
    SELECT
        ci.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR  FROM s.sale_date) AS year,
        SUM(s.total)                    AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci     ON ci.city_id = c.city_id
    GROUP BY ci.city_name, month, year
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS current_month_sale,
        LAG(total_sale, 1) OVER(
            PARTITION BY city_name
            ORDER BY year, month
        ) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    current_month_sale,
    last_month_sale,
    ROUND(
        (current_month_sale - last_month_sale)::numeric /
        last_month_sale::numeric * 100
    , 2) AS growth_rate_pct
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;
```

---

### Q10. Market Potential Analysis
**Identify the top cities by total sales, including rent, customer count, and estimated coffee consumers.**

```sql
WITH city_sales AS (
    SELECT
        ci.city_name,
        SUM(s.total)                  AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total)::numeric /
            COUNT(DISTINCT s.customer_id)::numeric
        , 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci     ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumers_millions
    FROM city
)
SELECT
    cr.city_name,
    cs.total_revenue,
    cr.estimated_rent           AS total_rent,
    cs.total_customers,
    cr.estimated_coffee_consumers_millions,
    cs.avg_sale_per_customer,
    ROUND(
        cr.estimated_rent::numeric /
        cs.total_customers::numeric
    , 2) AS avg_rent_per_customer
FROM city_rent AS cr
JOIN city_sales AS cs ON cr.city_name = cs.city_name
ORDER BY cs.total_revenue DESC;
```

---

## Recommendations

Based on the analysis, the top three cities recommended for new Monday Coffee store openings are:

### City 1: Pune
- Average rent per customer is the lowest among all cities.
- Generates the highest total revenue.
- Average sales per customer is strong, indicating high spending per visit.

### City 2: Delhi
- Has the highest estimated coffee consumer base at 7.7 million.
- Largest customer count at 68 unique customers.
- Average rent per customer sits at 330, well within a sustainable range.

### City 3: Jaipur
- Highest number of unique customers at 69.
- Lowest average rent per customer at just 156, making it highly cost-efficient.
- Average sales per customer of 11.6k shows solid revenue potential.

---

## SQL Concepts Used

- **Joins**: multi-table joins across sales, customers, city, and products
- **Aggregation**: `SUM`, `COUNT`, `ROUND` with `GROUP BY`
- **CTEs**: multi-step logic broken into readable `WITH` blocks
- **Window Functions**: `DENSE_RANK()` for product rankings, `LAG()` for month-on-month growth
- **Date Functions**: `EXTRACT()` for filtering and grouping by month, quarter, and year
- **Type Casting**: `::numeric` for precise division and rounding

---

## Tools Used

- PostgreSQL
- pgAdmin / any SQL client

---

*Project by Euodia Sam*
