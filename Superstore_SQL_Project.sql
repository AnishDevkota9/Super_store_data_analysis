-- We here loaded the csv excel file that we had. So we are going to dig into the dataset of us .
select * from Orders$;

select * from Returns$;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Data of ours was sucessfully loaded in Orders and Return table of SALE database
-- Checking out the type of the data in both table

select  COLUMN_NAME , DATA_TYPE
from INFORMATION_SCHEMA.columns
where TABLE_NAME = 'Orders$';

select COLUMN_NAME , DATA_TYPE
from INFORMATION_SCHEMA.columns
where TABLE_NAME = 'Returns$';

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- So we have seen through the data types, now then we will be creating the cte and join Order and return table
-- And through the CTE we will be adding the values to the New table where we will be working on with because we are not changing the database tables.

with our_cte as
( select Orders$.*, Returns$.Returned as Returned_status
from Orders$ 
left join Returns$
on Orders$.order_id = Returns$.[Order ID] and 
Orders$.market = Returns$.Market)

select * into Working_table 
from our_cte;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- So let me make a view of the cte so by which i can directly select the view and find what the acutal joined data is whenever needed

create view Our_view 
as
( select Orders$.*, Returns$.Returned as Returned_status
from Orders$ 
left join Returns$
on Orders$.order_id = Returns$.[Order ID] and 
Orders$.market = Returns$.Market)

select * from Our_view;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Now we have got the table that we are going to be working on with
-- Lets look after it and the data types and do some data adding and cleaning
-- Importantly , we did not create the temporary table because for the future use our new database table' Working_table' can be helpful for further analysis and data extraction.

select * from Working_table;

select COLUMN_NAME , DATA_TYPE
from INFORMATION_SCHEMA.columns
where TABLE_NAME = 'Working_table';
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Lets add some columns that might be giving us more insights to our data and make our working table more efficient

alter table Working_table
add FInal_sales_amount as (total_without_discount - Discount_amount), --dont need to declare the value types because it self gives the proper value according to calculation
Shippment_days as datediff(day, order_date, ship_date);

select  FInal_sales_amount from Working_table;

select * from Working_table
where Returned_status is null;

update Working_table
set Returned_status = ' Complete_sales'
where Returned_status is null;

update Working_table
set Returned_status = ' Returned '
where Returned_status = 'Yes';
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- We here cleaned and added the required columns for our table 
-- lets look for the duplicate values if there exist or not

select * , ROW_NUMBER() over (partition by order_id, product_name order by order_id) as rownumber
from 
Working_table
order by rownumber desc
;

-- so we found out that no duplicate column was there luckily if there was it to be found then we could also have use cte for further removal of duplicates
-- lets check if there is any nulls or not

select * from Working_table
where order_id is null or Final_sales_amount is null;
 
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- So didnt have any nulls which would have been misleading in our data so finally we can say our data to be clean and ready for analysis.
-- Now we will be doing the exploratory data analysis on our table. 

select * from Working_table 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- what were the top 20 sales record with the highest total profit for clear sales

select top 20 * from Working_table
where Returned_status = ' Complete_sales'
order by profit desc;

-- if we want the above data and columns only order_id , ship_mode, market , category , profit
-- we could have used limit but SQL SERVER dont provide that function so lets use Top

select top 20 order_id , ship_mode , market , category ,  profit from 
Working_table
where Returned_status = ' Complete_sales'
order by profit desc;

 -------------------------------------------------------------------------------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- lowest 20 sales with the lowest profit within the complete sales
 
 select top 20 * from Working_table
 where Returned_status = ' Complete_sales'
 order by profit ;

 select top 20 order_id , ship_mode , market , category ,  profit from 
Working_table
where Returned_status = 'Complete_sales'
order by profit asc;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- sum of total sales according to ship_mode that would have been made if all the returned sales were not returned

select sum(FInal_sales_amount) , ship_mode
from Working_table
group by ship_mode;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- which country was best on the sales based on sales_amount

select country , sum(  FInal_sales_amount)  Sales_Amount
from Working_table
--where Returned_status = ' Complete_sales'
group by country
order by Sales_Amount desc;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- find out the market's and their number of orders placed 

select market , count(*) as no_of_orders from Working_table
group by market
order by no_of_orders ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- count the total complete sales vs returned order
select Returned_status, count(*) orders_count from Working_table
group by 
Returned_status;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- give the average shipment days taken for the country Canada

select AVG(Shippment_days) Average_Days_For_Shipment from Working_table;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- give the 10 (cutsomer_name , sum of total , returned_status (i.e must be a complete_sales) , and year along with the profit in total)  whom gave the highest profit

select top 10 customer_name, sum(FInal_sales_amount) as Sales_amount , 
sum(profit) as Profit, [year] from Working_table
where Returned_status = ' Complete_sales'
group by customer_name, [year]
order by Profit;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- give the order_id along with the product name from matched product_id using the self join statement

select a.order_id ,b.product_name from Working_table a
left join 
Working_table b on 
a.order_id = b.order_id
and a.product_id = b.product_id
and a.product_name = b.product_name
group by b.order_id , a.order_id, a.product_name , b.product_name
order by a.order_id ;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Find the total profit amount that could have been collected from the returned order status

select sum(profit) as PROFIT_MIGHT_HAVE_EXTENDED, segment
from Working_table
where Returned_status = ' Returned'
group by segment

select sum(profit) PROFIT_WOULD_HAVE_BEEN_DONE,segment from Working_table 
group by segment;

select sum(profit) ACTUAL_PROFIT_MADE ,segment from Working_table 
where Returned_status= ' Complete_sales'
group by segment;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- OR we could have done by creating temporary table and join the temporary tables. So, we can do this and display the output when  required  as below:
select sum(profit) as PROFIT_MIGHT_HAVE_EXTENDED, segment
into #temp_tbl1
from Working_table
where Returned_status = ' Returned'
group by segment;

select sum(profit) PROFIT_WOULD_HAVE_BEEN_DONE,segment 
into #temp_tbl2
from Working_table 
group by segment;

select sum(profit) ACTUAL_PROFIT_MADE ,segment 
into #temp_tbl3 from Working_table
where Returned_status= ' Complete_sales'
group by segment;

select #temp_tbl1.PROFIT_MIGHT_HAVE_EXTENDED
, #temp_tbl2.PROFIT_WOULD_HAVE_BEEN_DONE ,
#temp_tbl3.ACTUAL_PROFIT_MADE , #temp_tbl1.segment
from #temp_tbl1
join #temp_tbl2 on #temp_tbl1.segment = #temp_tbl2.segment
join #temp_tbl3 on #temp_tbl1.segment = #temp_tbl3.segment
group by #temp_tbl1.segment,#temp_tbl2.segment,
#temp_tbl3.segment, #temp_tbl1.PROFIT_MIGHT_HAVE_EXTENDED,
#temp_tbl2.PROFIT_WOULD_HAVE_BEEN_DONE,#temp_tbl3.ACTUAL_PROFIT_MADE;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Which are the 3 country with maximum number of orders. Provide the aggregate counts

select top 3 count(*) as number_of_orders, country from Working_table
group by country
order by number_of_orders desc;

-- which are the 3 bottom country with minimum number of orders

select top 3 count(*) as number_of_orders, country from Working_table
group by country
order by number_of_orders asc;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- which segment which has the total sales more than 5000000

select segment , sum(Final_sales_amount) as Sales_amount from Working_table
where Returned_status = ' Complete_sales'
group by segment
having sum(FInal_sales_amount) > 5000000;

-- markets and their sucessfull final sales amount
select market , sum(Final_sales_amount) as Sales_amount from Working_table
where Returned_status = ' Complete_sales'
group by market;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- how much worth sales made per years on the complete sales. this query must helps in identifying the sales performance according to year

select [year] , sum(Final_sales_amount) as Sales , category 
from Working_table
where Returned_status = ' Complete_sales'
group by category , [year]
order by [year];

-- how much worth sales value made per year that were failure. This query must helps in identifying which year had unusal orders or returned orders.

select [year] , sum(Final_sales_amount) as Sales_RETURN , category 
from Working_table
where Returned_status = ' Returned'
group by category , [year]
order by [year];

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- give an output of sub-category and sum of the final sales where the return status dont matters . 
--And give a new column where it would state  a sales with less than 1000000 as quite - less, less than 2000000 as good , more than 2000000 as very good

select sub_category , sum(Final_sales_amount) as FInal_Sales
,case 
when sum(Final_sales_amount) < 200000 then 'Poor Sales in amount'
when sum(Final_sales_amount) <= 500000 then 'Quite Average Sales in amount'
when sum(Final_sales_amount) < 1000000 then 'Very Good Sales in amount'
when sum(Final_sales_amount) > 1000000 then 'Extremely good Sales in amount'
end as 
Sales_Status
from Working_table
group by sub_category
order by FInal_Sales;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Provide a column specifying the country , category , segment , final slaes , discount amount and the profit. Here , we are required to display the agrregated data.

select country , category , segment , sum(Final_sales_amount) as Total , sum(Discount_amount) as Discount_given , sum(profit) as Profit 
from Working_table
group by country , category , segment
order by  country;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- How many times was the product 'Nokia Signal Booster, Full Size' being sold.

select count(*) from Working_table
where product_name = 'Nokia Signal Booster, Full Size';

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- How many orders for Phones were completed and returned_ respectively

select count(*), Returned_status
from Working_table
where sub_category = 'Phones'
group by Returned_status;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Output  Working_table and Return table to exactly display all the information of the returned sales with the ship mode First Class from working table , and market as China and APAC from return table

select a.* 
from Working_table a
where 
order_id in (select [Order ID] from Returns$)
and market in (select Market from Returns$ where Market = 'APAC')
and ship_mode = 'First Class';

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- how many discint products were being listed and ordered. 

select count(distinct(product_name)) from Working_table;

-- What was the highest selling product all over the United_states .

select top 1 count(*) as Total_num_order , product_name , country 
from Working_table
where country = 'United States'
group by product_name,country
order by Total_num_order desc;

-- what product selling was good over all  market.

select product_name , count(*) as total_orders
from Working_table
group by product_name
order by total_orders desc;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- how much revenue generated by Maria Etezadi , display along with the count of orders done (both status order) and segments ordered

select customer_name, count(*) order_counts, sum(FInal_sales_amount) Sales_amount, 
segment, Returned_status 
, sum(profit) Profit_given_by
from Working_table
group by customer_name, segment, Returned_status
having customer_name ='Maria Etezadi';
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Provide the country name along with market where market is APAC.

select distinct(country) , market as MARKET_APAC
from Working_table
where market = 'APAC';

-- create a view that gives the sum of quantity for different category with segment , year having successful status/ order . This can be helpful in identifying the market demand of categories throughout the year

create view Market_Demand as
( select sum(quantity) as Quantity_of_demand, category, segment , [year] 
from Working_table
group by segment , [year], category
)

select * from Market_Demand order by [year];

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- top 5 customers with the highest amount order
select top 5 sum(Final_sales_amount) Amount , customer_name , count(*) as number_of_orders
from Working_table
group by customer_name
order by  Amount desc;

-- top 5 customers with the lowest amount orders
select top 5 sum(Final_sales_amount) Amount , customer_name , count(*) as number_of_orders
from Working_table
group by customer_name
order by  Amount asc;

--top 5 customers with high number of returned_status shipment

select top 5 customer_name , count(Returned_status) as number_of_orders_returned
from Working_table
where Returned_status = ' Returned'
group by customer_name
order by  number_of_orders_returned desc;

-- top 5 customers with sucessfull amount of complete_sales orders

select top 5 customer_name , count(Returned_status) as number_of_orders_successful
from Working_table
where Returned_status = ' Complete_sales'
group by customer_name
order by  number_of_orders_successful desc;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- what was the profit_amount on each market

select sum(profit) as Profit , market from Working_table
where Returned_status = ' Complete_sales'
group by market;

-- average discount amounts given through the different country

select AVG(Discount_amount) as DISCOUNT_AVERAGE , country 
from Working_table
where Returned_status = ' Complete_sales'
group by country
order by DISCOUNT_AVERAGE desc;

-- Which Ship_mode was used more during the orders

select ship_mode, count(ship_mode) as Counts from Working_table
group by ship_mode;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------\

-- As a bonus lets look after some sub queries task that we can do in our task.

-- If we want to retrive all the information based on the return status. so we can do it by simply join statements. 
-- Here so we can explore how it is to be done without using join and by using sub query
select a.*
from Working_table a
where 
order_id in (select [Order ID] from Returns$)
and market in (select Market from Returns$);

--basically lets do a select sub query

select  a.category , (select sum(Final_sales_amount) from Working_table) as AvgAMount
from Working_table a
group by  category;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- We can do more exploratory analysis through the given data from here and extract the data table into excel or csv format. 
-- SO in this project we did major data analysis using the sql 
-- we even cleaned the data , add the columns whenever required 
-- updated the data tables , created views, ctes , joins, case statements
-- We showed the sub queries statements as well
-- DId some mathematical calculations and data exploartion.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Lastly we have a case if the user is not allowed to use the query in the database. 
-- Then the user wants the data from new table Working_table on which we did the data analysis process. 
-- But not authorized for writing query. So inorder to make this available we can use stored procedure where we copy the data from Working_table 
-- so executing that Procedure, user can access the data and go on for further data exctraction or analysis phase.

create procedure Working_table_procedure 
as ( select * from Working_table); 

-- note the procedure cant be accssed by the select so 

exec Working_table_procedure;

-- Stored Procedure with parameter as category

create procedure parametered_procedure_category
@category nvarchar(20)
as (
select * from Working_table
where category = @category);

exec parametered_procedure_category @category = 'furniture'