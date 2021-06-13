------------------------------------------------------------------------------------------------
--Exercise A
--Import the three csv files into a SQL database and answer the following questions using SQL.
--You can create the database however you’d like, but please use SQL to solve these questions.
-------------------------------------------------------------------------------------------------

--question 1
--How many orders were completed in 2018?(Note: We operate in US/Eastern timezone)

select extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) as ordered_year
    , count(distinct order_number) as num_of_orders
from orders 
where extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) = 2018
group by extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY'))
--ORDERED_YEAR, NUM_OF_ORDERS
--2018	35258

with orders_new as(
    select extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) as ordered_year
        , orders.*
    from orders 
)
    select o.ordered_year
        , count(distinct o.order_number) as num_of_orders
    from orders_new o
    inner join line_items l
        on o.order_number = l.order_number
    where o.ordered_year = 2018
    group by o.ordered_year
--ORDERED_YEAR, NUM_OF_ORDERS
--2018	33653

--Answers to Q1: 
--35258 orders were completed in 2018 but only 33653 orders have coresponding line_items information. 


--question 2
--How many orders were completed in 2018 containing at least 10 units?

with orders_new as(
    select extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) as ordered_year
        , orders.*
    from orders 
), join_tables as (
    select o.ordered_year
        , o.order_number
        , sum(units_sold) as units
    from orders_new o
    inner join line_items l
        on o.order_number = l.order_number
    where o.ordered_year = 2018
    group by o.ordered_year
        , o.order_number
)
    select ordered_year
        , count(distinct order_number) as num_orders_ge10units
    from join_tables
    where units >= 10
    group by ordered_year
--ORDERED_YEAR, NUM_ORDERS_GE10UNITS
--2018	21952

--Answers to Q2: 
--21952 orders  were completed in 2018 containing at least 10 units.


--Question 3
--How many customers have ever purchased a medium sized sweater with a discount?

with orders_new as(
    select extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) as ordered_year
        , orders.*
    from orders 
), join_tables as (
    select o.ordered_year
        , o.order_number
        , o.customer_uuid
        , o.discount
        , o.ordered_at_utc
        , p.description
        ,p.product_size
    from orders_new o
    inner join line_items l
        on o.order_number = l.order_number
    inner join products p
        on l.product_id = p.product_id
    where p.description like('%Sweater') and p.product_size = 'M' and o.discount > 0     
)
    select min(ordered_at_utc) as date_start
        , max(ordered_at_utc) as date_end
        , count(distinct customer_uuid) as distinct_cust
    from join_tables

--Answers to Q3: 
--3423 distinct customers have ever purchased a medium sized sweater with a discount

--Question 4
--How profitable was our most profitable month? (Profit = Revenue - Cost)

with orders_new as(
    select extract (year from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) as ordered_year
        , extract (month from to_date(substr(from_tz(to_timestamp(ordered_at_utc,'yyyy-mm-dd hh24:mi:ss'), 'UTC') at time zone 'America/New_York', 1,9),'DD-mon-YY')) as ordered_month
        , orders.*
    from orders 
), join_tables as (
    select o.ordered_year
        , o.ordered_month
        , o.order_number
        , o.customer_uuid
        , o.discount
        , o.ordered_at_utc
        , l.product_id
        , l.units_sold
        , p.selling_price
        , p.supplier_cost
    from orders_new o
    inner join line_items l
        on o.order_number = l.order_number
    inner join products p
        on l.product_id = p.product_id
)
    select ordered_year
        , ordered_month
        , sum(units_sold*selling_price*(1-discount)-units_sold*supplier_cost) as profit
    from join_tables
    group by ordered_year, ordered_month
    order by sum(units_sold*selling_price*(1-discount)-units_sold*supplier_cost) desc
    
--Answers to Q4: 
--2019-10 was our most profitable month