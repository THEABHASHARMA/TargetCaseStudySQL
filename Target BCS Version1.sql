--                                                   "TARGET CASE STUDY"



#Q.Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset


#Q.1.1   Data type of all columns in the "customers" table
SELECT * FROM `Target.INFORMATION_SCHEMA.COLUMNS`; 

SELECT 
    column_name, 
    data_type
FROM 
   `Target.INFORMATION_SCHEMA.COLUMNS`
WHERE
    table_name = 'customers';

-- 2. Get the time range between which the orders were placed. SELECT

SELECT min(order_purchase_timestamp) as First_order, 
       max(order_purchase_timestamp ) as last_order, 
       date_diff(max(order_purchase_timestamp ), 
       min(order_purchase_timestamp), day) as Difference_in_days 
FROM `Target.orders`;

-- 3. Count the Cities & States of customers who ordered during the given period.

SELECT
  count(distinct customer_city) as City_count, 
  count(distinct customer_state) as State_count FROM
`Target.customers` as c JOIN `Target.orders` as o
ON c.customer_id = o.customer_id;

-- 2. In-depth Exploration:
-- 1. Is there a growing trend in the no. of orders placed over the past years?
-- Growing trends considering year-on-year analysis for 2016, 2017, and 2018 isn’t much insightful here, assuming that the question is asking month-on-month analysis.

SELECT EXTRACT( Year from order_purchase_timestamp) AS order_year,
       EXTRACT( month from order_purchase_timestamp) AS order_month, 
      COUNT(*) AS order_count
FROM `Target.orders` 
GROUP BY
      order_year, order_month 
ORDER BY
      order_year, order_month;

-- From September 2016 to November 2017, there is a general upward trend in order counts, indicating overall growth in orders placed. However, this growth trend was disrupted in December 2017, and the orders count dropped, recovered back from January 2018 and was stable and dropped drastically again in September 2018.

-- 2. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
SELECT
    EXTRACT( month from order_purchase_timestamp) AS order_month, 
    COUNT(*) AS order_count
FROM `Target.orders`
GROUP BY 
    order_month
ORDER BY
    Order_month;

-- There is a general trend of higher order counts in the middle months of the year (May, June, July, August), possibly due to summer holiday shopping, indicating that these months might be popular for shopping.
-- September has the lowest order count in this dataset. It might be worth investigating potential reasons for the sudden and significant drop in orders during this month.


-- 3. During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
-- ● 0-6 hrs : Dawn
-- ● 7-12 hrs : Mornings
-- ● 13-18 hrs : Afternoon
-- ● 19-23 hrs : Night
SELECT 
    CASE
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
        ELSE 'Night'
    END AS time_of_day, 
    COUNT(*) AS order_count
FROM 
    `Target.orders`
GROUP BY 
    time_of_day
ORDER BY 
    order_count DESC;

-- Most orders were placed during the afternoon followed by Night.


-- 3. . Evolution of E-commerce orders in the Brazil region:
-- 1. Get the month on month no. of orders placed in each state.
SELECT
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS order_month,
    c.customer_state AS state,
    COUNT(*) AS order_count
FROM
    `Target.orders` AS o
JOIN 
    `Target.customers` AS c ON o.customer_id = c.customer_id
GROUP BY 
    order_month, state
ORDER BY 
    order_month, state, order_count;

-- 2. How are the customers distributed across all the states?
SELECT 
    customer_state, 
    count(*) as customer_count
FROM 
    `Target.customers`
GROUP BY 
    customer_state
ORDER BY 
     customer_count desc;


-- 4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.
-- 1. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
-- You can use the "payment_value" column in the payments table to get the cost of orders.
WITH CTE AS (
    SELECT *
    FROM `Target.payments` AS p
    JOIN `Target.orders` AS o ON p.order_id = o.order_id
    WHERE EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8 
      AND EXTRACT(YEAR FROM o.order_purchase_timestamp) BETWEEN 2017 AND 2018
), 
CTE2 AS (
    SELECT 
        EXTRACT(YEAR FROM order_purchase_timestamp) AS year, 
        SUM(payment_value) AS cost
    FROM CTE
    GROUP BY year
    ORDER BY year
)
SELECT 
    year, 
    ROUND(cost, 2) AS cost, 
    LEAD(cost) OVER (ORDER BY year) AS next_year_value, 
    ROUND(((LEAD(cost) OVER (ORDER BY year) - cost) / cost) * 100, 2) AS percent_increase
FROM 
    CTE2;

-- There is a 136.98 % increase in the cost of orders from 2017 to 2018.

-- 2. Calculate the Total & Average value of order price for each state.
SELECT
    c.customer_state, 
    ROUND(SUM(oil.price), 2) AS total_price,
    ROUND(SUM(oil.price) / COUNT(DISTINCT oil.order_id), 2) AS average_price
FROM 
    `Target.customers` AS c
JOIN 
    `Target.orders` AS o ON c.customer_id = o.customer_id
JOIN 
    `Target.order_items` AS oil ON oil.order_id = o.order_id
GROUP BY 
    c.customer_state 
ORDER BY 
    c.customer_state;

-- 3.Calculate the Total & Average value of order freight for each state.
SELECT
    c.customer_state, 
    ROUND(SUM(oil.price), 2) AS total_price,
    ROUND(SUM(oil.price) / COUNT(DISTINCT oil.order_id), 2) AS average_price
FROM 
    `Target.customers` AS c
JOIN 
    `Target.orders` AS o ON c.customer_id = o.customer_id
JOIN 
    `Target.order_items` AS oil ON oil.order_id = o.order_id
GROUP BY 
    c.customer_state 
ORDER BY 
    c.customer_state;

-- 5. Analysis based on sales, freight and delivery time.
-- 1. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
-- Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
-- Do this in a single query.
-- You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
-- ● time_to_deliver = order_delivered_customer_date - order_purchase_timestamp ● diff_estimated_delivery = order_estimated_delivery_date -
-- order_delivered_customer_date
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    TIMESTAMP_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
    TIMESTAMP_DIFF(order_delivered_customer_date, order_estimated_delivery_date, DAY) AS diff_estimated_delivery
FROM 
    `Target.orders`
WHERE 
    order_status = 'delivered';

-- 87182 orders out of 96478 were delivered before the estimated delivery date.

-- 2. Find out the top 5 states with the highest & lowest average freight value.
WITH CTE AS (
    SELECT 
        c.customer_state,
        ROUND(SUM(oil.freight_value) / COUNT(DISTINCT oil.order_id), 2) AS average_freight_value
    FROM 
        `Target.customers` AS c
    JOIN 
        `Target.orders` AS o ON c.customer_id = o.customer_id
    JOIN 
        `Target.order_items` AS oil ON oil.order_id = o.order_id
    GROUP BY 
        c.customer_state
)
-- Top 5 Lowest Average Freight
(SELECT 
    'Top 5 Lowest Average Freight' AS category, 
    customer_state, 
    average_freight_value
FROM 
    CTE 
ORDER BY 
    average_freight_value
LIMIT 5)

UNION ALL

-- Top 5 Highest Average Freight
(SELECT 
    'Top 5 Highest Average Freight' AS category, 
    customer_state, 
    average_freight_value
FROM 
    CTE
ORDER BY 
    average_freight_value DESC
LIMIT 5);


-- 3. Find out the top 5 states with the highest & lowest average delivery time.

WITH CTE AS (
    SELECT 
        c.customer_state, 
        ROUND(SUM(TIMESTAMP_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY)) / COUNT(DISTINCT c.customer_id), 2) AS average_delivery_time
    FROM 
        `Target.customers` AS c 
    JOIN 
        `Target.orders` AS o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_state
)
-- Top 5 Lowest Average Delivery Time
(SELECT 
    'Top 5 Lowest Average Delivery Time' AS category, 
    customer_state, 
    average_delivery_time
FROM 
    CTE
ORDER BY 
    average_delivery_time
LIMIT 5)

UNION ALL

-- Top 5 Highest Average Delivery Time
(SELECT 
    'Top 5 Highest Average Delivery Time' AS category, 
    customer_state, 
    average_delivery_time
FROM 
    CTE
ORDER BY 
    average_delivery_time DESC
LIMIT 5);

-- 4. Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
-- You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.
SELECT 
    c.customer_state,
    ROUND(SUM(TIMESTAMP_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY)) 
          / COUNT(DISTINCT c.customer_id), 2) AS diff_estimated_delivery
FROM 
    `Target.customers` AS c
JOIN 
    `Target.orders` AS o ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_state
ORDER BY 
    diff_estimated_delivery DESC
LIMIT 5;


-- 6. Analysis based on the payments:
-- 1. Find the month on month no. of orders placed using different payment types.
SELECT 
    p.payment_type,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS Month,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS Year,
    COUNT(*) AS order_count
FROM 
    `Target.payments` AS p
JOIN 
    `Target.orders` AS o ON p.order_id = o.order_id
GROUP BY 
    p.payment_type, Year, Month
ORDER BY 
    Year, Month, p.payment_type;

-- Most used payment method was credit_card followed by UPI

-- 2. Find the no. of orders placed on the basis of the payment installments that have been paid.
SELECT 
    payment_installments, 
    COUNT(*) AS order_count
FROM 
    `Target.payments`
WHERE 
    payment_installments > 1
GROUP BY 
    payment_installments;
