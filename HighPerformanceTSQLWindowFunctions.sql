--*********************************************DATABASE AND TABLE:
--database TSQL2012 available : https://raw.githubusercontent.com/justkacz/MSSQL/main/DataBase_TSQL2012.sql
-- Northwind : https://raw.githubusercontent.com/justkacz/MSSQL/main/Northwind_Database.sql

select *
into ODet
from TSQL2012.Sales.OrderDetails

select *
into Orders2
from TSQL2012.Sales.Orders

select o.*, od.productid, od.unitprice, od.qty, od.discount
, od.qty * od.unitprice as val
into OrdDet
from Orders2 o
join ODet od
on o.orderid=od.orderid

select  
from [Sales].[Orders]
select * from [Sales].[OrderDetails]

select * from Orders
select * from OrderDetails

select * from OrdDet

--cube vs rollup vs grouping sets:
--cube => grouping of all dimensions 2^Number of arguments: (a,b)->(a)->(b)->()
select YEAR(orderdate) year, DATEPART(Q, orderdate) qty, sum(val)
from OrdDet
group by cube(YEAR(orderdate), DATEPART(Q, orderdate))

-- rollup => N+1, comparing to cube - rollup does not have groups for quarters (a,b)-> (a) -> ()
select YEAR(orderdate) year, DATEPART(Q, orderdate) qty, sum(val)
from OrdDet
group by rollup(YEAR(orderdate), DATEPART(Q, orderdate))

--grouping sets: exact groups are defined by user:
select YEAR(orderdate) year, DATEPART(Q, orderdate) qty, sum(val)
from OrdDet
group by grouping sets (
	(YEAR(orderdate)),
	(YEAR(orderdate), DATEPART(Q, orderdate))
)

-- query that returns orders from June and country Germany which value exceeds avg amount
select *
from 
	(select orderid, custid, orderdate, shipcountry, val, avg(val) over() as mean
	from OrdDet
	where shipcountry='Germany' and month(orderdate) =06
	) x
where val > mean

-- 48% query that returns information about all orders from three customers generating the highest income
select distinct custid, tot
from (
select custid, tot, dense_RANK() over(order by tot desc) r
from 
	(select custid, SUM(val) over(partition by custid) tot
	from OrdDet) x
	) y
where r<4
order by tot desc

-- 44% or using top 3:
select *
from orddet 
where custid in (
	select custid from(
		select top 3 custid, SUM(val) tot
		from OrdDet
		group by custid
		order by tot desc) x )

-- 8% correlated subqueries - often less efficient than joins, in this case the best - only 8% comparing to above:
select CustomerID, companyname, 
		(select COUNT(o.OrderID)
			from orders o
			where C.CustomerID=o.CustomerID) as orderCount
from Customers C
order by orderCount desc


-- joining multiple rows into one:
-- 72% using stuff & xml path:

select country, 
	STUFF(		-- input_string, start_position, length(deleting items), replace_with_substring => used to delete the first comma:
		(select ', '+ c1.city
		from Customers c1
		where c1.Country=c2.country
		FOR XML PATH('')),
	1,2,'') as City
from Customers c2
group by Country, city

-- 28% or with using string_agg:
select country, string_agg(city, ', ') as city
from Customers
group by country

-- 50% query that returns the latest order from each customer:
select c.CustomerID, c.CompanyName, MAX(O.orderid) as lastOrder
from Customers C
	join orders O
		on C.CustomerID=O.CustomerID
group by c.CustomerID, c.CompanyName

-- 50% or using correlated subquery:
select c.customerid, c.companyname, 
	(select MAX(o.orderid)
	from orders O
	where O.CustomerID=c.customerid) as lastOrder
from Customers c

--CTE:
with x (employeeid, reportsto, firstname, lastname, organisationlevel)
as
(
	select employeeid, reportsto, firstname, lastname, 0
	from Employees
	where ReportsTo is null -- selecting BOSS

	union all

	select e.employeeid, e.reportsto, e.firstname, e.lastname, organisationlevel+1
	from Employees e
		join x
			on e.ReportsTo=x.EmployeeID  --to the x anchor table are adding new employees who become managers for the next employees
)
select * from x
option(maxrecursion 1000)


select e1.employeeid, e1.firstname, e1.lastname, e1.firstname+' ' + e1.lastname+ ' reports to '+e2.firstname+' '+ e2.lastname
from Employees e1
	left join Employees e2
	on e1.ReportsTo=e2.EmployeeID


--UDF:
Select NEWID() as UniqueIdentifier, GETDATE() as DataCzas

-- function that returns the number of working days between two dates:
create function WD(@startdate datetime, @enddate datetime)
returns int
begin
		declare @date_diff int =0

		while @startdate<=@enddate
		begin
			if (datename(dw, @startdate) != 'Saturday' and  datename(dw, @startdate) != 'Sunday') set @date_diff=@date_diff+1
			set @startdate= @startdate+1
		end 
		return @date_diff-1
end
select dbo.WD('2022-05-12', '2023-05-12');

--the number of working days between order date and shipped date:
select OrderID, OrderDate, ShippedDate, dbo.WD(OrderDate, ShippedDate) as Working_days
from [Orders]
order by Working_days desc

-- efficiency comparison udf vs correlated query vs window function:
-- query that returns orders details which value exceeds the average order values of each client: 

--join statement with subquery:
select o.customerID, o.OrderID, sum(od.UnitPrice*od.Quantity) as OrdVal
from [Orders] o
	join [Order Details] od
	on o.OrderID=od.OrderID
group by o.CustomerID, o.OrderID
having sum(od.UnitPrice*od.Quantity) >
			(select avg(OrdVal) avgVal
			 	from 
				(select o2.CustomerID, o2.OrderID, sum(od2.UnitPrice * od2.Quantity) as OrdVal
				from [Orders] o2
				inner join [Order Details] od2
					on o2.OrderID=od2.OrderID 
 				where o.CustomerID=o2.CustomerID   --joining customers from outer and inner queries
				group by o2.CustomerID, o2.OrderID) x) 

