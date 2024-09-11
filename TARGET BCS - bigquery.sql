
--                                                   "TARGET CASE STUDY"



#Q.Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset


#Q.1.1   Data type of all columns in the "customers" table

select * from `target`.INFORMATION_SCHEMA.TABLES;

select column_name,data_type
from `target`.INFORMATION_SCHEMA.COLUMNS
where table_name= 'customers';

#Q.1.2   Get the time range between which the orders were placed.

select 
min(order_purchase_timestamp) as mintime,
max(order_purchase_timestamp) as maxtime,
from `target.orders`;

#Q.1.3   Count the number of Cities and States in our dataset.

select 
count(distinct geolocation_city) as NoOfCities, 
count(distinct geolocation_state) as NoOfStates
from `target.geolocation`;

---or

with cte as 
(
select 
geolocation_city as city,
geolocation_state as state
from `target.geolocation`
group by geolocation_city,geolocation_state

union all

select 
customer_city as city,
customer_state as state
from `target.customers` 

union all

select
seller_city as city,
seller_state as state 
from `target.sellers`
)

select count(distinct city) as no_of_city,
count(distinct state) as no_of_State
from cte;

----------------------------------------------------------------------------------------------------------------------------------------


#In-depth Exploration:

#  2.1    Is there a growing trend in the no. of orders placed over the past years?

-- if no. of orders placed has increased gradually in each month, over the years bcuz 2016 incomplete , 2018 sept only 1 order...so go for orders monthwise....

select * from `target.orders`;
--- mistake
select distinct period,total_orders,Growth_trend from (
select 
concat(year,'-',mnth)as period,
sum(no_of_orders)as total_orders,
round(((no_of_orders-lag(no_of_orders) over(order by mnth))/lag(no_of_orders) over(order by mnth))*100,2) as Growth_trend
from
(
select 
extract(year from order_purchase_timestamp)as year,
extract(month from order_purchase_timestamp)as mnth,
count(*) as no_of_orders
from `target.orders`
where order_status not in ('canceled','unavailable')
group by order_purchase_timestamp,mnth
order by year,mnth
)
group by year,mnth,no_of_orders,period
order by year,mnth
);
--pblm


-- or  monthwise
with cte as
(
select 
concat(year,'-',mnth)as period,
sum(no_of_orders)as total_orders,
lag(sum(no_of_orders)) over(order by year,mnth)as lagg
from
(
select 
extract(year from order_purchase_timestamp)as year,
extract(month from order_purchase_timestamp)as mnth,
count(*)as no_of_orders
from `target.orders`
where order_status not in ('canceled','unavailable') and extract(year from order_purchase_timestamp) >= 2017 
group by order_purchase_timestamp,year,mnth
order by year,mnth
)
group by year,mnth
order by year,mnth)

select period,total_orders,Growth_trend 
from
(select * ,concat(round(((total_orders-lagg)/lagg)*100,2),'  %') as Growth_trend
from cte);

--or   year wise

with cte as (
(
  select extract(year from order_purchase_timestamp) as year,
  count(*) as no_of_orders
  from `target.orders`
  where order_status <>'canceled'
  group by 1
  order by 1
)
)

select *,
concat(round(((No_of_Orders-lagg)/lagg)*100,2),'  %') as growth_trend
from 
(
  select *,
  lag(no_of_orders) over(order by year)as lagg
  from cte
  order by 1
);

#   2.2   Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

--find out if the no. of orders placed are at peak during which months

select 
concat(period,' -- is ',mth)as monthly_season,
Max_orders
from
(
select
concat(year,' - ',mnth)as period,
sum(no_of_orders)as Max_orders,
case 
when mnth=1 then 'January'
when mnth=2 then 'Feburary'
when mnth=3 then 'March'
when mnth=4 then 'April'
when mnth=5 then 'May'
when mnth=6 then 'June'
when mnth=7 then 'July'
when mnth=8 then 'August'
when mnth=9 then 'September'
when mnth=10 then 'October'
when mnth=11 then 'November'
else 'December'
end as mth
from
(
select 
extract(year from order_purchase_timestamp)as year,
extract(month from order_purchase_timestamp)as mnth,
count(*) as no_of_orders,
from `target.orders`
where order_status <>'canceled'
group by order_purchase_timestamp,year,mnth
order by year,mnth
)
group by year,mnth
)
order by  2 desc;

#   2.3  During what time of the day, do the Brazilian customers mostly place their orders?
--(Dawn, Morning, Afternoon or Night)
--0-6 hrs : Dawn
--7-12 hrs : Mornings
--13-18 hrs : Afternoon
--19-23 hrs : Night

with cte as
(
select
case
when extract(hour from order_purchase_timestamp) between 0 and 6 then 'DAWN'
when extract(hour from order_purchase_timestamp) between 7 and 12 then 'MORNING'
when extract(hour from order_purchase_timestamp) between 13 and 18 then 'AFTERNOON'
else 'NIGHT'
end as TIME_OF_DAY,
count(*)as Orders_placed
from `target.orders`
group by TIME_OF_DAY
)

select * from cte
order by 2 desc
limit 1;


#  3.  Evolution of E-commerce orders in the Brazil region:
#A.   3.1 Get the month on month no. of orders placed in each state.
--no. of orders placed in each state, in each month

select yr_mnth,state,
min(monthly_orders) over(partition by yr_mnth)as Min_orders_recd,
max(monthly_orders) over(partition by yr_mnth) as Max_orders_recd,
round(avg(monthly_orders) over(partition by state order by yr_mnth),3) as Avg_monthly_order,
monthly_orders as Total_ordersPerMonth,
sum(monthly_orders) over(partition by state)as Monthly_state_order
from
(
select customer_state as state,
format_timestamp("%Y-%m",order_purchase_timestamp) as yr_mnth,
count(*)as monthly_orders
from `target.customers` c
join `target.orders` o 
on c.customer_id=o.customer_id
where order_status not in ('canceled','unavailable')
group by customer_state,yr_mnth
order by customer_state,yr_mnth
)
group by monthly_orders,yr_mnth,State
order by 2 asc;



--   3.2   How are the customers distributed across all the states?


select
customer_state,
count(customer_unique_id) AS No_of_unique_customers
from `target.customers`
group by customer_state
order by customer_state;

--or



select *,(no_of_customers-no_of_unique_customers)as customers_purchased_more
from
(
select customer_state,
count(distinct customer_id)as no_of_customers,
count(distinct customer_unique_id)as no_of_unique_customers
from `target.customers`
group by customer_state
order by 1
)as nt;




# 4 Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.


--  4.1  Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).


--monthwise

with cte as (
select month,
round(sum(if(year=2018,amt,0)),2) as cost_2018,
round(sum(if(year=2017,amt,0)),2) as cost_2017
from
(
select 
extract(year from order_purchase_timestamp)as year,
extract(month from order_purchase_timestamp)as mn,
format_timestamp("%b",order_purchase_timestamp) as month,
sum(p.payment_value)as amt
from `target.payments` p
join `target.orders` o 
on p.order_id=o.order_id
where order_status not in ('canceled','unavailable')
group by mn,order_purchase_timestamp
order by mn
)as n
where n.mn < 9  and year <> 2016
group by mn,month
order by mn
)

select month,
concat(cost_2017,'  -  REAIs')as Amt_2017,
concat(cost_2018,'  -  REAIs')as Amt_2018,
concat(round((((cost_2018-cost_2017)/cost_2017)*100),2),'  %') as percent_increased
from cte;




--yrwise
with cte as (
select
round(sum(if(year=2018,amt,0)),2) as cost_2018,
round(sum(if(year=2017,amt,0)),2) as cost_2017
from
(
select 
extract(year from order_purchase_timestamp)as year,
extract(month from order_purchase_timestamp)as mn,
sum(p.payment_value)as amt
from `target.payments` p
join `target.orders` o 
on p.order_id=o.order_id
group by order_purchase_timestamp
order by year
)as n
where n.mn < 9  and year <> 2016
)

select concat(cost_2017,'  -  REAIs')as Amt_2017,concat(cost_2018,'  -  REAIs')as Amt_2018,
concat(round((((cost_2018-cost_2017)/cost_2017)*100),2),'  %') as percent_increased
from cte;




#B.  4.2 	Calculate the Total & Average value of order price for each state.


-- using payment value
select customer_state , 
concat(round(sum(payment_value),2),'  REAIs') as Total_amount,
concat(round(avg(payment_value),2),'  REAIs') as Avg_amt
from `target.customers` c
join `target.orders` o 
on c.customer_id=o.customer_id
join`target.payments` p 
on p.order_id = o.order_id
group by customer_state
order by customer_state;

--using order price

select customer_state , 
concat(round(sum(oi.price),2),'  REAIs') as Total_amount,
concat(round(avg(oi.price),2),'  REAIs') as Avg_amt
from `target.customers` c
join `target.orders` o 
on c.customer_id=o.customer_id
join`target.order_items`oi 
on oi.order_id = o.order_id
group by customer_state
order by customer_state;



#Q 4.3  Calculate the Total & Average value of order freight for each state.


select customer_state , 
concat(round(sum(distinct freight_value),2),'  REAIs') as Total_freight_value,
concat(round(avg(freight_value),2),'  REAIs') as Avg_freight_value
from `target.customers` c
join `target.orders` o on c.customer_id=o.customer_id
join`target.order_items` oi on oi.order_id = o.order_id
group by customer_state
order by customer_state;


#  5.1  A.	Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. 
--Also, calculate the difference (in days) between the estimated & actual delivery date of an order. 

with cte as (
select order_id,
extract(date from order_purchase_timestamp)as order_purchase_date,
extract(date from order_delivered_customer_date)as delivered_customer_date,
extract(date from order_estimated_delivery_date)as estimated_delivery_date
from `target.orders` 
)
select order_id,
concat(date_diff(cte.delivered_customer_date,cte.order_purchase_date,day),'  Days') as time_to_delivery,
concat(date_diff(cte.estimated_delivery_date,cte.delivered_customer_date,day),'  Days') as diff_time_delivery
from cte;

--or (diff is there based on time extraction) ---  but results same

select
order_id,
datetime_diff(order_delivered_customer_date,order_purchase_timestamp,day) as delivery_time,
datetime_diff(order_estimated_delivery_date,order_delivered_customer_date,day) as diff_estimated_delivery
from
`target.orders`;


-- 5.2   B. Find out the top 5 states with the highest & lowest average freight value.

select state ,avg_freight_value from
(
(
select concat('HIGH #   ',customer_state) as state, 
max(freight_value) as High_freight_value,
concat(round(avg(freight_value),2),' REAIs') as avg_freight_value
from `target.customers` c
join `target.orders` o on c.customer_id=o.customer_id
join `target.order_items` as p on o.order_id = p.order_id
group by customer_state
order by 3 desc
limit 5 
)
union all
(
select concat('LOW #   ',customer_state) as state,
min(freight_value) as low_freight_value,
concat(round(avg(freight_value),2),' REAIs') as avg_freight_value
from `target.customers` c
join `target.orders` o on c.customer_id=o.customer_id
join `target.order_items` as p on o.order_id = p.order_id
group by customer_state
order by 3 asc
limit 5
)
)as t;

-- or


with cte as
(
select State,'High'as val,avg_freight_value, 
dense_rank() over (order by avg_freight_value desc) as avg_rank
from
(
select customer_state as state,round(avg(freight_value),2) as avg_freight_value
from `target.customers` as c
join `target.orders` as o on c.customer_id = o.customer_id
join `target.order_items` as p on o.order_id = p.order_id
group by customer_state
) nt1

union all

select state,"Low"as val,avg_freight_value, 
dense_rank() over (order by avg_freight_value asc) as avg_rank
from
(
select customer_state as state,round(avg(freight_value),2) as avg_freight_value
from `target.customers` as c
join `target.orders` as o on c.customer_id = o.customer_id
join `target.order_items` as p on o.order_id = p.order_id
group by customer_state
) nt2
)

select concat(val," - ",avg_rank) as fv_order,state,concat(cte.avg_freight_value,'  REAIs')as Avg_Freight_cost 
from cte 
where avg_rank<=5
order by fv_order;



--   5.3  Find out the top 5 states with the highest & lowest average delivery time.

with cte as
(
select state,'FAST'as val,avg(delivery_time) as avg_delivery_time,
dense_rank() over (order by avg(delivery_time) desc) as rnk
from
(
select customer_state as state,
datetime_diff(order_delivered_customer_date,order_purchase_timestamp,day) as delivery_time,
from `target.customers` as c
join `target.orders` as o on c.customer_id = o.customer_id
group by state,order_delivered_customer_date,order_purchase_timestamp,delivery_time
) nt1
group by state

union all

select state,'SLOW'as val,avg(delivery_time) as avg_delivery_time,
dense_rank() over (order by avg(delivery_time) asc) as rnk
from
(
select customer_state as state,
datetime_diff(order_delivered_customer_date,order_purchase_timestamp,day) as delivery_time,
from `target.customers` as c
join `target.orders` as o on c.customer_id = o.customer_id
group by state,order_delivered_customer_date,order_purchase_timestamp,delivery_time
) nt2
group by state
)

select concat(val," - ",rnk) as speed_of_delivery,state,round(avg_delivery_time,2)as Avg_delivery_time
from cte 
where rnk<=5
order by 1;

--*********************************************************************************************************************


--5.4  D.	Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery. You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.

select customer_state as state,
round(avg(date_diff(o.order_estimated_delivery_date,o.order_delivered_customer_date,day)),2)as avg_speed_delivery
from `target.customers` as c
join `target.orders` as o on c.customer_id = o.customer_id
group by state
order by avg_speed_delivery desc
limit 5;


-- or

-- work on it 
with avg_delivery as 
(
select customer_state as state,
round((avg(date_diff(date(order_estimated_delivery_date), date(order_delivered_customer_date), DAY))),0) as Avg_diff_esti_deli,
row_number() over(order by avg(date_diff(date(order_estimated_delivery_date),date(order_delivered_customer_date)),day))desc) as quick_delivery
from `target.order_items` as o
join `target.orders` as od on o.order_id = od.order_id
join `target.customers` as c on od.customer_id = c.customer_id
where order_delivered_customer_date is not null
group by customer_state
)

select customer_state as states,
Avg_diff_estimated_delivery
FROM avg_delivery
WHERE top_fast_delivery <= 5
order by Avg_diff_estimated_delivery desc



# 6.Analysis based on the payments:
--A.   6.1  Find the month on month no. of orders placed using different payment types


select 
format_timestamp('%Y-%m', o.order_purchase_timestamp)as period,
count(case when payment_type='credit_card' then 1 end) as CREDIT_CARD,
count(case when payment_type='debit_card' then 1  end)as DEBIT_CARD,
count(case when payment_type='UPI' then 1 end) as UPI,
count(case when payment_type='voucher' then 1 end) as VOUCHER,
count(case when payment_type='not_defined' then 1 end)as NOT_DEFINED,
count(case when payment_type is null then 1 end)as NOT_KNOWN,
count(o.order_id)as total_orders
from `target.payments` p
join `target.orders` o 
on p.order_id=o.order_id
where payment_type is not null and order_status not in ('canceled','unavailable') 
group by period
order by period;



---or



select ym,
payment_type,
sum(cnt)as Total_orders 
from 
(
select 
format_timestamp("%Y-%m",order_purchase_timestamp) as ym,
payment_type,
count(p.order_id)as cnt
from `target.payments` p
join `target.orders` o 
on p.order_id=o.order_id
group by order_purchase_timestamp,payment_type
)
where payment_type is not null
group by payment_type,ym
order by ym;

or
-- check this (sm mistake in values)
SELECT
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) AS Month,
  COUNTIF(p.payment_type = 'credit_card') AS Credit_Card,
  COUNTIF(p.payment_type = 'debit_card') AS Debit_Card,
  COUNTIF(p.payment_type = 'voucher') AS Voucher,
  COUNTIF(p.payment_type = 'UPI') AS UPI,
  COUNTIF(p.payment_type = 'not_defined') AS Not_Defined,
  COUNTIF(p.payment_type is null) AS Unavialble,
  count(distinct o.order_id) as Total_order
FROM `target.orders` AS o
join `target.payments` AS p ON o.order_id = p.order_id
where order_status not in ('canceled','unavailable')
GROUP BY Month
ORDER BY Month;



#    6.2  Find the no. of orders placed on the basis of the payment installments that have been paid.(0 zero installment means down payment)



select payment_installments,
count(distinct order_id) as No_of_Orders
from `target.payments`
where payment_installments <> 0
group by 1
order by 1

---------------------------------------------------------------------------------------------

-- #####    7.     additional ques (defined by me)


--a) Count the no.of.orders based on order status


select order_status,
count(order_status) as no_of_orders,
from `target.orders`
group by order_status;


--b)	Count the total orders based on product category?


select product_category,
count(order_id) as no_of_orders,
from `target.products`p
join `target.order_items`o
on o.product_id=p.product_id
group by product_category
order by 2 desc


--c) calculate the average review score for each product ?

select product_category, round(avg(review_score),2)as avg_rating
from `target.order_reviews`rw
join `target.order_items`oi on oi.order_id=rw.order_id
join `target.products`p on p.product_id=oi.product_id
group by 1


select 
count(distinct customer_city) as city,
count(distinct customer_state) as state
from `target.customers` 
