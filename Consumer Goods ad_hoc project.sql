use gdb023;
## Q1
-- Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select distinct market 
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';


## Q2
-- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg


with up_2020 as (select count(distinct product_code) as unique_products_2020 
				from fact_sales_monthly 
                where fiscal_year=2020 ),
     up_2021 as (select count(distinct product_code) as unique_products_2021  
				from fact_sales_monthly 
                where fiscal_year=2021),
     percent_chng as (select (((unique_products_2021 - unique_products_2020) / unique_products_2020)*100) as percentage_chng 
				from up_2020,up_2021)
select * 
from up_2020, up_2021, percent_chng;


## Q3 : 
-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment, count(distinct product_code) as product_count 
from dim_product
group by segment
order by product_count desc;


#Q4:
-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference



with f_2020 as (select segment, count(distinct product_code) as product_count_2020
			from dim_product
            join fact_sales_monthly
            using (product_code)
            where fiscal_year = 2020
            group by segment),
	 f_2021 as (select segment, count(distinct product_code) as product_count_2021
			from dim_product
            join fact_sales_monthly
            using (product_code)
            where fiscal_year = 2021
            group by segment)
select segment, product_count_2020,product_count_2021,(product_count_2021 - product_count_2020) as difference
from f_2020 f
join f_2021 f2
using (segment)
order by difference desc;


#Q5:
--  Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost


select product_code, product, manufacturing_cost
from dim_product
join fact_manufacturing_cost
using (product_code)
where manufacturing_cost in (
		(select max(manufacturing_cost) from fact_manufacturing_cost),
        (select min(manufacturing_cost) from fact_manufacturing_cost)
        );
        
        
#Q6:
-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

with cte1 as(select customer_code, customer, round(avg(pre_invoice_discount_pct)*100) as average_discount_percentage
			from dim_customer c
			join fact_pre_invoice_deductions d
			using (customer_code)
			where d.fiscal_year=2021 and c.market = 'India'
			group by customer_code
			order by average_discount_percentage desc limit 5)
select customer_code, customer, concat(average_discount_percentage,'%') as average_discount_percentage
from cte1;


# Q7:
-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount


select month(date) as month,
	   year(date) as year,
	   sum(round((g.gross_price * s.sold_quantity),2)) as gross_sales_amount
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price g
on g.product_code = s.product_code
where customer = 'Atliq Exclusive'
group by month, year
order by year, month;


# Q8
-- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

with  quarters as (select *,
				case
				when month(date) in (9,10,11) then 'Q1'
				when month(date) in (12,1,2) then 'Q2'
				when month(date) in (3,4,5) then 'Q3'
				when month(date) in (6,7,8) then 'Q4'
				end as Quarter
				from fact_sales_monthly
                where fiscal_year = 2020)
select Quarter, sum(sold_quantity) as total_sold_quantity
from quarters
group by Quarter
order by total_sold_quantity desc;


#Q9:
-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with cte1 as(select 
			channel, 
			round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln
			from fact_sales_monthly s
			join dim_customer c
			using (customer_code)
			join fact_gross_price g
			using (product_code, fiscal_year)
			where s.fiscal_year = 2021
			group by channel
			order by gross_sales_mln desc)
select *,
	  gross_sales_mln*100/sum(gross_sales_mln) over() as percentage
	from cte1;
    
  
  
#Q10:
-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order


with cte1 as (select 
				division, p.product_code, product, sum(sold_quantity) as total_sold_quantity
			  from fact_sales_monthly s
              join dim_product p
              using (product_code)
              where fiscal_year = 2021
              group by division, product_code, product
              order by total_sold_quantity desc),
	 cte2 as (select *,
	            rank() over(partition by division order by total_sold_quantity desc) as rank_order
	         from cte1)
select * 
	from cte2
	where rank_order<=3;