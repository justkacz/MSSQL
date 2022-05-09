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

-- ****************************************************TABULAR FUNCTION - used in FROM clause:
-- function that returns order number, date and order values for each client:
create function CustDetails(@custid varchar(max))
returns table
as
return
(
	select o.orderid, o.customerid, o.orderdate, od.Quantity*od.UnitPrice as OrdVal
	from Orders o
		join [dbo].[Order Details] od
		on o.OrderID=od.OrderID
		where customerid=@custid
)
drop function dbo.CustDetails

select * from dbo.CustDetails('VINET')

-- using tabular function with inner join to extract more details about selected customer:
select c.*, cd.*
from [dbo].[Customers] c
	inner join dbo.CustDetails('VINET') cd
	on c.CustomerID=cd.customerid

-- APPLY -> allows to run function multiple times: (for each row cross join is applied (like inner join))
select c.*, cd.*
from [dbo].[Customers] c
	cross apply dbo.CustDetails(c.customerid) cd  --(to include non matching rows outer apply must be used)
where country='Spain'

-- ***************************************************** BUILT IN FUNCTIONS:
--extracting dial code, call prefix;
select left(homephone, charindex(')', homephone))
from [dbo].[Employees]

-- product name with name length less than 10 chars:
select ProductName, LEN(productname) 
from [dbo].[Products]
where LEN(productname)<10  -- function LEN is called two times for each record, using functions in the where clause has negative impact on efficiency

-- extracting domain address:

select WebPage, LEFT(WebPage, CHARINDEX('/', WebPage, 8)) as sub_str,
CHARINDEX('/', WebPage, 8),  
SUBSTRING(WebPage, 8,  CHARINDEX('/', WebPage, 8)-8)  --exp, startlocation, n -> how many elements
from (
	SELECT 'http://www.google.pl/next_page/' as WebPage
	UNION
	SELECT 'http://google.pl/sql-tutorial/' ) x

-- extracting post code:
select patindex('%[0-9][0-9]-[0-9][0-9][0-9]%', Adres) as position,		--patindex - returns the position of matching substring
	substring(Adres, patindex( '%[0-9][0-9]-[0-9][0-9][0-9]%', Adres), 6) as postCode
FROM
(
	SELECT '60-144 Poznañ' as Adres 
	UNION
	SELECT 'Poznañ, 60-186'
	UNION 
	SELECT 'Kod pocztowy 61-698, Poznañ' 
	UNION 
	SELECT 'Poznañ 61-698, Jana Paw³a 16' 
 
) as Adresy

-- STUFF(original, start_p, no_repl, replacing_string) vs REPLACE(original, old_char, new_char)

--DATE TIME FUNCTIONS:
SELECT SYSDATETIME(), 
       SYSDATETIMEOFFSET(),
       GETDATE(),
       GETUTCDATE()

-- the first day of the current month, the last day of the previous month:
select GETDATE() -datepart(d,GETDATE()-1)  as firstday
	,GETDATE() -datepart(d,GETDATE()) as lastday

-- function that returns the first day of month:
create function FirstDay(@data as datetime)
returns datetime
begin
	set @data = (select @data- DATEPART(D, @data)+1) 
	return @data

end

create function LastDay(@data datetime)
returns datetime
as 
begin
	set @data=(select DATEADD(m, 1, @data-DATEPART(D, @data)+1)-1)
	return @data
end

select dbo.FirstDay('2022-07-20')
select dbo.LastDay('2022-07-20')

-- function that counts exact age:
create function ExactAge(@birthdate datetime)
returns int
as
begin
	declare @wiek int
	   set @wiek = (select datediff(YEAR, @birthdate, GETDATE())-
						case 
							when DATEPART(DY, GETDATE())< DATEPART(dy, DATEFROMPARTS(year(getdate()), MONTH(@birthdate), day(@birthdate))) then 1 else 0
					end)
	return @wiek
end

select dbo.ExactAge('1999-05-01')

--MATH FUNCTIONS:
--number from range 0-10 => formula: min + convert(int, (max-min+1)*RAND())
select 0+ convert(int, (20-10+1)*RAND())

--number from range 10-20:
select 10+ convert(int, (20-10+1)*RAND())

--ISDATE(), ISNUMERIC() - might be used in the select and where clauses e.g. to filter only rows with date format
select ISDATE(GETDATE()), ISDATE( '2013/01/02' ), ISDATE( '20131402' )

-- LEN()- returns the number of items, DATALENGTH()-returns the number of bytes (ASCII-> 1 byte per element, UNICODE->with N at the beginning, 2 bytes per element)
select LEN('SQL tutorial')
select DATALENGTH('SQL tutorial')
select DATALENGTH(N'SQL tutorial')

select orderid, sum(freight), max(suma)
from
(
select orderid, freight, SUM(freight) over (partition by orderid) as suma
from OrdDet) x
group by orderid 

--NTILE - split freight cost column over 4 equal groups with range frames:  in Python => pd.qcut()
-- conclusion -> positive skew
select nt, MIN(freight) as 'range_from',
	MAX(freight) as 'range_to',
	MAX(freight)-MIN(freight) as range_size,
	COUNT(orderid) as no_orders
from (
select orderid, freight,
	NTILE(4) over (order by freight) as nt
from OrdDet) x
group by nt

-- **********************************************CONNECTION WITH REMOTE SERVER:
--the list of available providers OLEDB (Object Linking and Embedding Database) :
EXEC xp_enum_oledb_providers

--universal library: MSDASQL