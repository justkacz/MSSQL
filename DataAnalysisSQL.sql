-- NOTHWIND DATABASE - > https://raw.githubusercontent.com/justkacz/MSSQL/main/Northwind_Database.sql



-- modulo - its result might be used to extract rows with such a digit as the last item:
select *
from orders
where OrderID % 10=6 --% 100 will result with 06


-- query that returns tables where columns like Orderid and customerid exist
select TABLE_SCHEMA, TABLE_NAME, count(distinct column_name)
from INFORMATION_SCHEMA.COLUMNS
where COLUMN_NAME = 'OrderID' or COLUMN_NAME ='CustomerID'
group by TABLE_SCHEMA, TABLE_NAME
having count(distinct column_name)>1

-- histogram - query that returns the the distribution of orders per customer (how mny customers made particular number of orders)
select top 5 *
from orders

select orders, COUNT(CustomerID) num_cust
from (select CustomerID, COUNT(OrderID) orders
		from Orders
		group by CustomerID) x
group by orders



--bins:
select o.OrderID, os.Subtotal,
		case when Subtotal<=100 then 'up to 100'
			when Subtotal<=500 then '100 to 500'
			else '500+'
		end as description
from [dbo].[Order Subtotals] os
join Orders o
on o.OrderID=os.OrderID


-- number of items in each bin:
select description, COUNT(orderid) no_orders
from (select o.OrderID, os.Subtotal,
		case when Subtotal<=100 then 'up to 100'
			when Subtotal<=500 then '100 to 500'
			else '500+'
		end as description,
		case when Subtotal<=100 then 1
			when Subtotal<=500 then 2
			else 3
		end as r
	from [dbo].[Order Subtotals] os
	join Orders o
	on o.OrderID=os.OrderID
	) x
group by description, r
order by r

-- create bins using logarithm or NTILE window function: 
select o.OrderID, o.CustomerID, os.Subtotal, 
	LOG10(os.Subtotal) as logSub, 
	NTILE(10) over(order by os.Subtotal)
from [dbo].[Order Subtotals] os
join [Orders Qry] o
on o.OrderID=os.OrderID

-- confirmation that each bin contains equal number of items:
select ntile, 
	MIN(subt) as minv,
	MAX(subt) as maxv, 
	COUNT(orderid) as orders
from (
	select o.OrderID orderid, o.CustomerID, os.Subtotal subt, 
		NTILE(10) over(order by os.Subtotal) as ntile
	from [dbo].[Order Subtotals] os
	join [Orders Qry] o
	on o.OrderID=os.OrderID) x
group by ntile

-- 

select ROW_NUMBER() over(order by orderid) r, * 
from orders 
order by ROW_NUMBER() over(order by orderid)
offset 5 rows 
fetch next 10 rows only

--the sum of freight for each country depending on year:
select shipcountry,
	sum(case when YEAR(orderdate) = 1996 then Freight else 0 end) as freight_1996,
	sum(case when YEAR(orderdate) = 1997 then Freight else 0 end) as freight_1997,
	sum(case when YEAR(orderdate) = 1998 then Freight else 0 end) as freight_1998
from orders 
group by shipcountry

-- or with using pivot table: