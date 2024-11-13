# Target-Business-Case-Study-SQL-
Target case study analyzes its Brazilian e-commerce business from 2016 to 2018. The data includes details on customers, orders, products, payments, and reviews.

This project is to understand customer behaviour, pricing, efficiency, and areas for improvement. Exploration will focus on order trends, seasonality, delivery times, and payment methods to help Target optimize their Brazilian e-commerce strategy through data-driven decisions.

The thought process is documented here, and all the coding can be found in the folders on this project.

#### Dataset Schema

<img width="465" alt="Screenshot 2024-11-13 at 3 39 40 PM" src="https://github.com/user-attachments/assets/bd3db716-a4ab-4d60-8d42-728d59b3560c">



## Questions to be answered

### Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:
1.Data type of all columns in the "customers" table.

2.Get the time range between which the orders were placed.

3.Count the Cities & States of customers who ordered during the given period.

### In-depth Exploration:
4.Is there a growing trend in the no. of orders placed over the past years?

5.Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

6.During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
0-6 hrs : Dawn
7-12 hrs : Mornings
13-18 hrs : Afternoon
19-23 hrs : Night

### Evolution of E-commerce orders in the Brazil region:
6.Get the month on month no. of orders placed in each state.

7.How are the customers distributed across all the states?

### Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.
9.Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
You can use the "payment_value" column in the payments table to get the cost of orders.

10.Calculate the Total & Average value of order price for each state.

11.Calculate the Total & Average value of order freight for each state.

### Analysis based on sales, freight and delivery time.
12.Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.

13.Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
Do this in a single query.
You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date

13.Find out the top 5 states with the highest & lowest average freight value.

14.Find out the top 5 states with the highest & lowest average delivery time.

15.Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.

### Analysis based on the payments:
16.Find the month on month no. of orders placed using different payment types.

17.Find the no. of orders placed on the basis of the payment installments that have been paid.

