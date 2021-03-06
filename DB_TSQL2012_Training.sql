--database script saved https://raw.githubusercontent.com/justkacz/MSSQL/main/DataBase_TSQL2012.sql

USE TSQL2012;

--verify data types in the choosen table (table name without schema name at the beginning)

SELECT DATA_TYPE, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME   = 'Suppliers'


-- ALL AT-ONCE concept - there is no order of evaluation of the expressions in the SELECT list:

-- COLLATION - is a property of character data that encapsulates several aspects, including language support, ort order, case sensitivity, accent sensitivity, and more.
SELECT name, description
FROM sys.fn_helpcollations();


-- *********************************************************************************FUNCTIONS OVERVIEW:

--Computing the number of occurences of the item put as an argument in the replace function:
select empid, lastname, len(lastname) - len(replace(lastname, 'e', '')) as num_occ
from HR.Employees

--format input with leading zeros using FORMAT function:
SELECT empid, lastname,
	format(len(lastname)-len(REPLACE(lastname, 'e', '')), '000000000') as no_occu
from HR.Employees;

--filling space with zeros:

--Any data type without the VAR element (CHAR, NCHAR) in its name has a fixed length, which means that SQL Server preserves space in the row based on the column?s defined size and not on
--the actual number of characters in the character string.
SELECT supplierid, RIGHT(REPLICATE('0', 9) + cast(supplierid as VARCHAR(10)), 4) as filled_col
from Production.Suppliers;


-- STUFF vs REPLACE:
-- replace - replaces existing characters of all occurrences:
SELECT REPLACE ('Johnnohneny','ohn','ccc'); --Jcccnccceny
SELECT STUFF ('Johnnohneny',2,3,'ccc'); --Jcccnohneny; first index =1

SELECT lastname
from [HR].[Employees]
where lastname like '[^D, P, C]%'
--the same as;

SELECT lastname
from [HR].[Employees]
where left(lastname, 1)!='D' and left(lastname, 1)!='P' and left(lastname, 1)!='C';

-- ESCAPE function with escape character - checking wildcard characters:
update [HR].[Employees]
set title ='Sales_Manager' where title = 'Sales Manager' --check title with '_'

select title
from [HR].[Employees]
where title like '%!_%' ESCAPE '!'; 
-- if the wildcard character belongs to %, _,[ the square brackets might be used instead of escape character: LIKE ?%[_]%?




--******************************************************************************************DATE/TIME:
--IMPLICIT CONVERSIONS - are not visible to the user. SQL Server automatically converts the data from one data type to another. according to the rules of datatype precedence.
--EXPLICIT CONVERSIONS -  if you don?t specify how SQL Server should convert the data types to do what you want (explicitly), it will try to guess your intentions (implicitly), (use the CAST or CONVERT functions)

SELECT @@LANGUAGE; --check current session's language, languages have own datetime format
--the output format is unchanged, setting only affects the way the values you enter are interpreted


select empid, orderdate 
from [Sales].[Orders]
where orderdate='20060704'; --SQL allows to specify a literal of a different type that can be converted, 
--SQL Server defines precedence among data types and will usually implicitly convert the operand that has a lower data type precedence to the one that has higher precedence.
--string has lower precedence with respect to date and time data types

--CAST/CONVERT/PARSE:
SELECT CONVERT(DATETIME, '02/12/2007', 101); -- the third argument is a style number
SELECT PARSE('02/12/2007' AS DATETIME USING 'en-US'); -- like CAST, additionally allows to indicate the culture;

select convert(datetime, birthdate, 107) as conv_birth
from [HR].[Employees]; 

--DATA RANGE FILTERING:
--in most cases, when you apply manipulation on the filtered column, SQL Server cannot use an index in an efficient manner:
--INSTEAD OF:
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2007;

--BETTER WAY: ( need to revise the predicate so that there is no manipulation on the filtered column)
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20070101' AND orderdate < '20080101';


-- TRY_CAST, TRY_CONVERT, and TRY_PARSE: if the input isn?t convertible to the target type, the function returns a NULL instead of failing the query.

-- non-equi join: join condition does not involve equality operator - joining (self join) to produce unique pair of employees:

select h1.empid, h1.firstname, h1.lastname,
	   h2.empid, h2.firstname, h2.lastname
from [HR].[Employees] h1
	join [HR].[Employees] h2
		on h1.empid>h2.empid;

-- outer join and inner join as a third table, adding where clause which refers to the result of the outer join will filter out 
-- all outer rows (there might be null values which comparing to any equation will result in unknown)

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O	--outer join
		ON C.custid = O.custid	
	JOIN Sales.OrderDetails AS OD	-- left join
		ON O.orderid = OD.orderid;	--customers with no orders will have null in orderid column, those rows will be filtered out although there was outer join

--Solution - using outer join in both statements or parentheses in the secend and third join

--multiplication of all table rows - helper column N with the continuous numbers as a condition in where clause (rows will be multiplied as many times as declared in where statement
select E.empid, E.firstname, E.lastname, N.n
from [dbo].[Nums] N
	cross join [HR].[Employees] E
		where N.n<10;	-- employees table will be multiplied 9 times


--extracting 5 consecutive days and repeating empid number:
select E.empid, DATEadd(DAY, N.n, '20090611') dt 
from [HR].[Employees] E
	cross join [dbo].[Nums] N
where N.n <6
order by E.empid;

--Return United States customers, and for each customer return the total number of orders and total quantities:
select top 5 * from [Sales].[Customers];
select top 5 * from [Sales].[Orders];
select top 5 * from [Sales].[OrderDetails];

select C.custid, C.Country, COUNT(distinct O.orderid) 'Num_orders', SUM(OD.qty) 'Total qty'
from [Sales].[Customers] C
	left join [Sales].[Orders] O
		on C.custid=O.custid
	left join [Sales].[OrderDetails] OD
		on O.orderid=OD.orderid
group by C.custid, C.Country
having country='USA';

-- Return customers who placed no orders:
select top 5 * from [Sales].[Customers];
select top 5 * from [Sales].[Orders];

select C.custid, C.companyname
from [Sales].[Customers] C
	left join [Sales].[Orders] O
		on C.custid=O.custid
where O.orderid is null;


--Return customers with orders placed on February 12, 2007, along with their orders:
select top 5 * from [Sales].[Customers];
select top 5 * from [Sales].[Orders];

select C.custid,C.companyname,  O.orderid, O.orderdate
from [Sales].[Customers] C
	left join [Sales].[Orders] O
		on C.custid=O.custid
	where O.orderdate =  '20070212';


--Return customers with orders placed on February 12, 2007, along with their orders. 
--Also return customers who didn?t place orders on February 12, 2007:

select top 5 * from [Sales].[Customers]
select top 5 * from [Sales].[Orders]

select C.custid, C.companyname, O.orderid, O.orderdate
from [Sales].[Customers] C
	left outer join [Sales].[Orders] O
		on C.custid=O.custid
	where O.orderdate =  '20070212'or O.orderid is null;	-- filter table cannot place in where clause, filtering must be until the final table is provided
															-- the filter on the order date should only determine matches and not be considered final in regard to the customer rows


--returning 'yes' or 'no' indicating whether there is a matching order

select C.custid, C.companyname, O.orderid, 
	case  
		when O.orderdate is null then 'No'
		else 'Yes'
	end As HasOrderOn20070212
from [Sales].[Customers] C 
left outer join [Sales].[Orders] O
	on C.custid=O.custid 
	and O.orderdate =  '20070212';

--*****************************************************SUBQUERIES:
-- the DISTINCT clause in the subquery does not have an impact on the performance

--extract order with the maximum order id:

declare @maxid as int = (select MAX(orderid) from [Sales].[Orders]);

select O.orderid, C.companyname
from [Sales].[Customers] C
	left join [Sales].[Orders] O
	on C.custid=O.custid
where orderid = @maxid;

-- if a subquery returns null => UNKNOWN - the query filters do not return this row

-- returns order IDs of orders placed by employees with a last name starting with D

select orderid, empid
from [Sales].[Orders]
where empid in (
	select empid 
	from [HR].[Employees]
	where lastname like 'D%');

-- customers who did not place any order:
select top 5 * from [Sales].[Customers];
select top 5 * from [Sales].[Orders];

select custid
from [Sales].[Customers]
where custid not in (select custid from [Sales].[Orders] );

--creating a new table Orders:
use TSQL2012
if OBJECT_ID('dbo.Orders', 'U') is not null drop table dbo.Orders; 
create table dbo.Orders(orderid int not null constraint Pkey primary key)

insert into dbo.Orders(orderid)
	select orderid
	from [Sales].[Orders]
	where orderid % 2 =0


-- return all individual order IDs that are missing between the minimum and maximum in the table:
declare @min int = (select MIN(orderid) from dbo.Orders)
declare @max int = (select MAX(orderid) from dbo.Orders)

select n
from dbo.Nums
where n between @min and @max
and n not in (select orderid from dbo.Orders)

--return for each order the percentage that the current order value is of the total values of all orders
-- a substitute for using window functions:
select top 5 * from [Sales].[OrderValues]

declare @sumval float(5) = (select sum(val) from [Sales].[OrderValues])

select orderid, custid, val, cast ((val/@sumval)*100 as numeric(5,2)) as percentage
from [Sales].[OrderValues]
order by custid

-- percentage for each particular customer:
select O1.orderid, O1.custid, O1.val, cast (100 * val/ (select SUM(val)
												from [Sales].[OrderValues] O2
												where O1.custid=O2.custid) as numeric(5,2)) as perc
from [Sales].[OrderValues] O1
order by custid

--return previous and next id (rows are not placed in any order, previous = max value lower than current row)
--instead of window function:
select orderid, orderdate, empid, custid, 
	(select MAX(orderid)
	from [Sales].[Orders] O2
	where O1.orderid>O2.orderid) as prev_id
from [Sales].[Orders] O1


select orderid, orderdate, empid, custid, 
	(select MIN(orderid) 
	from [Sales].[Orders] O2
	where O2.orderid>O1.orderid) as next_id
from [Sales].[Orders] O1


-- running aggregation (as an alternative to the window function):
select top 5 * from [Sales].[OrderTotalsByYear]

select orderyear, qty, 
		(select SUM(qty)
		from [Sales].[OrderTotalsByYear] O2
		where O2.orderyear<=O1.orderyear) running_qty
from [Sales].[OrderTotalsByYear] O1
order by orderyear


--struggling with NULL in a subquery: (when the null value appears in the customerid):
select *
into [Sales].[Orders2] --creating new table
from [Sales].[Orders]


insert into [Sales].[Orders2] values(NULL, 1, '20090212', '20090212',
'20090212', 1, 123.00, N'abc', N'abc', N'abc',
N'abc', N'abc', N'abc');

--running below code will result with empty statement:
select custid, companyname
from [Sales].[Customers]
where custid not in (select custid from [Sales].[Orders2])

--the last expression might be expanded with using customerid 22: 22 NOT IN (1, 2, NULL) => UNKNOWN
-- when IN predicate is used against a subquery that returns at least one NULL (UNKNOWN) operator the outer query always returns an empty set
--to avoid such situation - 1) column with id should be defined as NOT NULL, 
--2) NULL values should be excluded in the subquery

select custid, companyname
from [Sales].[Customers]
where custid not in (select custid from [Sales].[Orders2] where custid is not null)

--3) use NOT EXIST instead of NOT IN (always returns TRUE or FALSE never UNKNOWN):
select custid, companyname
from [Sales].[Customers] C
where not exists (select * 
				 from [Sales].[Orders2] O
				 where C.custid=O.custid)


--***************************************************NEW TABLE WITH SHIPPERS:
create table Sales.MyShippers(
	shipper_id int not null,
	companyname nvarchar(40) not null,
	phone nvarchar(24) not null,
	constraint PK_MyShippers primary key (shipper_id)
)
insert into Sales.MyShippers values(1, N'Shipper GVSUA', N'(503) 555-0137'),
(2, N'Shipper ETYNR', N'(425) 555-0136'),
(3, N'Shipper ZHISN', N'(415) 555-0138');

--**************************************************************************************************************************

--shippers who shipped orders to customer 43:
select top 5 * from [Sales].[Orders]
select top 5 * from [Sales].[MyShippers]

select custid, companyname 
from [Sales].[Orders] O
	left join [Sales].[MyShippers] MS
		on O.shipperid=MS.shipper_id
where custid=43

--query that returns all orders placed on the last day of activity that can be found in the Orders table
select top 5 * from [Sales].[Orders]
declare @maxdate as date = (select MAX(orderdate) from [Sales].[Orders])
--select @maxdate

select orderid, orderdate, custid, empid
from [Sales].[Orders]
where orderdate=@maxdate

--query that returns all orders placed by the customer(s) who placed the highest number of orders. Note that more than one customer might have the same number of orders:
select top 5 * from [Sales].[Orders]

declare @maxord as int = (select top 1 with ties custid
							from [Sales].[Orders]
							group by custid
							order by count(orderid) desc)
--select @maxord

select custid, orderid, orderdate, empid
from [Sales].[Orders] 
where custid=@maxord

-- query that returns employees who did not place orders on or after May 1, 2008:
select top 5 * from [HR].[Employees]
select top 5 * from [Sales].[Orders]

select empid, firstname, lastname
from [HR].[Employees]
where empid not in (select empid 
					from [Sales].[Orders]
					where orderdate >='20080501')


--query that returns countries where there are customers but not employees:
select top 5 * from [Sales].[Customers]
select top 5 * from [HR].[Employees]

select distinct(country) 
from [Sales].[Customers]
where country not in (select country from [HR].[Employees])

-- query that returns for each customer all orders placed on the customer?s last day of activity:
select top 5 * from [Sales].[Orders]

select custid, orderid, orderdate, empid
from [Sales].[Orders] O1
where orderdate= (select MAX(orderdate) 
					from [Sales].[Orders] O2
					where O1.custid=O2.custid) --allows to split and verify max value for the customers
order by custid

-- query that returns customers who placed orders in 2007 but not in 2008:
select top 5 * from [Sales].[Customers]
select top 5 * from [Sales].[Orders]

SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
	(SELECT *
	FROM Sales.Orders AS O
	WHERE O.custid = C.custid
	AND O.orderdate >= '20070101'
	AND O.orderdate < '20080101')
AND NOT EXISTS
	(SELECT *
	FROM Sales.Orders AS O
	WHERE O.custid = C.custid
	AND O.orderdate >= '20080101'
	AND O.orderdate < '20090101');


--query that returns customers who ordered product 12:
select top 5 * from [Sales].[Customers]
select top 5 * from [Sales].[Orders]
select top 5 * from [Sales].[OrderDetails]

select distinct(C.custid), C.companyname, OD.productid
from [Sales].[Customers] C
	left join [Sales].[Orders] SO
		on C.custid=SO.custid
	left join [Sales].[OrderDetails] OD
		on SO.orderid=OD.orderid
where productid=12


--query that calculates a running-total quantity for each customer and month:
select top 5 * from [Sales].[CustOrders]

select custid, ordermonth, qty, 
	(select SUM(qty) 
	from [Sales].[CustOrders] CO2 
	where CO1.custid=CO2.custid and CO2.ordermonth<=CO1.ordermonth) as running_qty
from [Sales].[CustOrders] CO1
order by custid


--*******************************************************************TABLE EXPRESSIONS:
--DERIVED TABLE - defined in the FROM clause:
-- * ORDER BY clause serves as part of the specification of the filter (top or offset-fetch), besides presentation
-- * all columns must have names (column aliases)
-- * all column names must be unique (might be achieved by adding aliases)
-- * column aliases might be used earlier than in ORDER BY clause

select top 5 * from [Sales].[Orders]

-- query that returns the number of customers in each year
-- with derived table:
select orderyear, COUNT(distinct custid) as numcust
	from (select YEAR(orderdate) as orderyear, custid
			from [Sales].[Orders]) D
group by orderyear

--stadard way:
select YEAR(orderdate), COUNT(distinct custid) as numcust
from [Sales].[Orders]
group by YEAR(orderdate)


--query that returns order years and the number of customers handled in each year only for years in which more than 70 customers were handled:
select orderyear,  custnum
from (select YEAR(orderdate) as orderyear, COUNT(distinct custid) as custnum
		from [Sales].[Orders]
		group by YEAR(orderdate)) D
where custnum>70 

--CTEs => COMMON TABLE EXPRESSIONS:
-- * several CTEs in one ststement do not have to refer to each other, they do not have to be nested
-- * alias declared in one CTE might be used in another when there is a reference to CTE in the FROM clause


--WITH <CTE_Name>[(<target_column_list>)]
--AS
--(
--	<inner_query_defining_CTE>
--)
--	<outer_query_against_CTE>;

-- CTE called USACusts, that returns all customers from the United States:
with USACusts as
(
	select custid from [Sales].[Customers]
	where country ='USA'
)
select * from USACusts

--query that returns order years and the number of customers handled in each year only for years in which more than 70 customers were handled:
with C1 as 
(
	select YEAR(orderdate) as yearorder, custid
	from [Sales].[Orders]
),
C2 as 
(
	select yearorder, COUNT(distinct custid) as numcust 
	from C1														-- reference to the first CTE C1
	group by yearorder
)
select yearorder, numcust
from C2
where numcust >70

-- multiple references in CTE - returns change in the number of customers:
with yearly_count as
(	
	select YEAR(orderdate) orderyear, COUNT(distinct(custid)) numcust
	from [Sales].[Orders]
	group by YEAR(orderdate)
)

select YC1.orderyear, YC1.numcust, coalesce(YC1.numcust-YC2.numcust, '-') as growth
from yearly_count YC1
	left join yearly_count YC2
	on YC1.orderyear=YC2.orderyear +1


-- VIEWS:
-- * views and inline table-valued functions - are reusable, their definitions are stored as database objects
-- * stored procedure sp_refreshview or sp_refreshsqlmodule, useful when new column is added to the table based on which the view is created
-- * ORDER BY clause can be used in views only with TOP, OFFSET-FETCH, or FOR XML

IF OBJECT_ID('Sales.USACusts') IS NOT NULL
	DROP VIEW Sales.USACusts;
GO

CREATE VIEW Sales.USACusts
AS
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO


select top 5 * from Sales.USACusts


-- diplaying the definition of the view:
--function:
select OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'))

-- or stored procedure:
exec sp_helptext 'Sales.USACusts'

-- adding ENCRYPTION to make definition of the view unavailable:
alter view Sales.USACusts with ENCRYPTION
as 

SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';

select OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts')) -- results with NULL

-- WITH SCHEMABINDING:
--It indicates that referenced objects cannot be dropped and that referenced columns cannot be dropped or altered

alter view Sales.USACusts with SCHEMABINDING
as

SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';

alter table Sales.Customers
drop column contacttitle		-- error: "The object 'USACusts' is dependent on column 'contacttitle'" 


-- a new row added to the view will be also added to the original table, even if it does not meet the condition in the view's WHERE clause:
insert into Sales.USACusts(companyname, contactname, contacttitle, address, city, region, postalcode, country, phone, fax)
values(N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE', N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789') --country = UK

select * from Sales.USACusts where country ='UK' --empty set
select * from Sales.Customers where country ='UK' and companyname like '%ABC%' --returns customer with id 92

-- WITH CHECK OPTION - prevents modifications that conflict with view's filter
alter view Sales.USACusts 
as
SELECT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
with check option;

insert into Sales.USACusts(companyname, contactname, contacttitle, address, city, region, postalcode, country, phone, fax)
values(N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE', N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789')
--error message: "The attempted insert or update failed..."

delete from [Sales].[Customers]
where custid>91

-- INLINE TABLE VALUED FUNCTION:
-- * like views but also supports input parameters

if OBJECT_ID('dbo.GetCustOrders') is not null
	drop function dbo.GetCustOrders
go

create function dbo.GetCustOrders (@cust_id as int) returns table
as
return
	SELECT orderid, custid, empid, orderdate, requireddate,
		shippeddate, shipperid, freight, shipname, shipaddress, shipcity,
		shipregion, shippostalcode, shipcountry
	from [Sales].[Orders]
	where custid=@cust_id
go

-- quering orders made by customer 1:
select orderid, custid, orderdate 
from dbo.GetCustOrders(1) as O

-- TVF as part of join:
select O.orderid, O.custid, OD.productid, OD.qty
from dbo.GetCustOrders(1) O
	left join [Sales].[OrderDetails] OD
	on O.orderid=OD.orderid



-- APPLY OPERATOR:
-- * operates on two input tables
-- * is very similar to a cross join, the difference between the join and APPLY operator becomes evident when you have a table-valued expression on the right side 
--   and you want this table-valued expression to be evaluated for each row from the left table expression.
-- * the APPLY operator allows to join two table expressions; the right table expression is processed every time for each row from the left table expression.
-- * two variants: CROSS APPLY (like INNER JOIN ) and OUTER APPLY (like LEFT OUTER JOIN): the same results might be achieved with using JOIN
--  but  the need of APPLY arises if there is a table-valued expression on the right part (with JOINs you cannot bind a value/variable from the outer query 
--  to the function as a parameter) and in some cases the use of the APPLY operator boosts performance of the query


--a join query between the derived table and the Orders table to return the orders with the maximum order date for each employee
select top 5 * from [Sales].[Orders]

select empid, MAX(orderdate) lastorder
from [Sales].[Orders]
group by empid

select O1.empid, O2.lastorder, O1.orderid, custid
from [Sales].[Orders] O1
	join (select empid, MAX(orderdate) lastorder
			from [Sales].[Orders]
			group by empid) O2
	on O1.empid=O2.empid
	and O1.orderdate=O2.lastorder


-- query that calculates a row number for each order based on orderdate, orderid ordering:
select orderid, orderdate, custid, empid, ROW_NUMBER() over(order by orderdate, orderid) rownum
from [Sales].[Orders]

--query that returns rows with row numbers 11 through 20 based on the row number definition from above example:

--Window functions (such as the ROW_ NUMBER function) are only allowed in the SELECT and ORDER BY clauses of a query, and not directly
-- in the WHERE clause.

with C1
as
(
	select orderid, orderdate, custid, empid, ROW_NUMBER() over(order by orderdate, orderid) as rownum
	from [Sales].[Orders]
)
select orderid, orderdate, custid, empid, rownum from C1 
where rownum >10 and rownum<21

--solution that uses a recursive CTE and returns the management chain leading to Zoya Dolgopyatova (employee ID 9):
select top 5 * from [HR].[Employees]

select empid, mgrid, firstname, lastname from [HR].[Employees]

with EMP 
as
(
	select empid, mgrid, firstname, lastname
	from [HR].[Employees]
	where empid=9

	union all

	select C.empid, C.mgrid, C.firstname, C.lastname
	from EMP E
		join [HR].[Employees] C
		on E.mgrid=C.empid
)
select * from EMP

--view that returns the total quantity for each employee and year
select top 5 * from [Sales].[Orders]
select top 5 * from [Sales].[OrderDetails]

create view Sales.VEmpOrders
as 
	select O.empid, year(O.orderdate) as orderyear, sum(qty) order_qty
		from [Sales].[Orders] O
			left join [Sales].[OrderDetails] OD
			on O.orderid=OD.orderid
	group by empid, year(O.orderdate)

select * from Sales.VEmpOrders order by empid, orderyear

--query against Sales.VEmpOrders that returns the running total quantity for each employee and year
select empid, orderyear, order_qty, (select SUM(order_qty)
									from Sales.VEmpOrders S1
									where S2.empid=S1.empid and S2.orderyear>=S1.orderyear) as runn_qty
from Sales.VEmpOrders S2
order by empid, orderyear


--an inline function that accepts as inputs a supplier ID (@supid AS INT) and a requested number of products (@n AS INT). The function should return @n products with the highest unit prices that
--are supplied by the specified supplier ID:
select top 5 * from [Production].[Products]

create function prodn(@supid AS INT, @n AS INT) returns table
as
	return
		select supplierid, productname, unitprice 
		from [Production].[Products]
		where supplierid = @supid
		order by unitprice desc
		offset 0 rows
		fetch next @n rows only

select * from prodn(5,2)

-- query that returns for each supplier, the two most expensive products using cross apply (like inner join) and above function prodn
select top 5 * from [Production].[Suppliers]



select S.supplierid, S.companyname, P.productid, P.productname, P.unitprice
from [Production].[Suppliers] S
	cross apply prodn(S.supplierid, 2) P -- like inner join, 


--SET OPERATORS:
-- * applied between two input sets (=mulisets)
-- * MULTISET - might contain DUPLICATES
-- * SET - only UNIQUE values
-- * SET operators: UNION (DISTINCT and ALL), INTERSECT (DISTINCT), and EXCEPT (DISTINCT).
-- * UNION - unifies the results of two input queries. If a row appears in any of the input sets, it will appear in the result of the UNION operator; UNION (=DISTINCT, returns SET), UNION ALL (resturns MULTISET), 
-- * two queries involved cannot have ORDER BY clause (query with an ORDER BY clause = CURSOR), ORDER BY might be applied only to the result operator
-- * two queries must provide result with the same number of columns and compatible data types (= the data type that is lower in terms of data type precedence must be implicitly convertible to the higher data types)
-- * the names of the columns in the result set are determined by the first query
-- * when it's comparing rows - two NULLs are considered as equal
-- * if no potential exists for duplicates the UNION ALL is recommended - removes the costs incurred by SQL checking for duplicates

-- * INTERSECT - set of all elements that belong to two sets, eliminates duplicate rows from the two input multisets (=turning them to SETs) and returns only rows that appear in both sets
--   as an alternative might be used INNER JOIN or EXISTS - but comparison with NULL values will yield UNKNOWN and such row will be filtered out, 


-- * EXCEPT (= DIFFERENCE ) -  first eliminates duplicate rows from the two input multisets?turning them to sets?and then returns only rows that appear in the first set but not the second.

-- * PRECEDENCE: with multiple set operators, first INTERSECT is evaluated, then UNION or EXCEPT based on order of appearance 
			--	 () parentheses
			--   1) INTERSECT 
			--	 2) UNION, EXCEPT 
	

-- query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10 without using a looping construct:
select 1 as n
union all
select 2
union all
select 3
union all
select 4
union all
select 5
union all
select 6
union all
select 7
union all
select 8
union all
select 9
union all
select 10;


--query that returns customer and employee pairs that had order activity in January 2008 but not in February 2008
select top 5 * from [Sales].[Orders]

--????????????????????????
--select custid, empid 
--from [Sales].[Orders] S1
--where exists (select * from [Sales].[Orders] S2 where S1.orderid=S2.orderid and S2.orderdate >='20080101' and S2.orderdate <'20080201')
--		and not exists (select * from [Sales].[Orders] S2 where S1.orderid=S2.orderid and S2.orderdate >='20080201' and S2.orderdate <'20080301')


select custid, empid 
from [Sales].[Orders]
where orderdate >='20080101' and orderdate <'20080201'
except
select custid, empid 
from [Sales].[Orders]
where orderdate >='20080201' and orderdate <'20080301'

--query that returns customer and employee pairs that had order activity in both January 2008 and February 2008
select custid, empid 
from [Sales].[Orders]
where orderdate >='20080101' and orderdate <'20080201'
intersect
select custid, empid 
from [Sales].[Orders]
where orderdate >='20080201' and orderdate <'20080301'

--query that returns customer and employee pairs that had order activity in both January 2008 and February 2008 but not in 2007
(select custid, empid 
from [Sales].[Orders]
where orderdate >='20080101' and orderdate <'20080201'
intersect
select custid, empid 
from [Sales].[Orders]
where orderdate >='20080201' and orderdate <'20080301')
except
select custid, empid 
from [Sales].[Orders]
where orderdate >='20070101' and orderdate <'20080101'

-- query that returns country, region, city from Employees and Suppliers and rows in each segment should be sorted by country, region, and city
select country, region, city
from (select 1 as constr, country, region, city
	  from [HR].[Employees]
	union all
	  select 2 as constr, country, region, city
	  from [Production].[Suppliers]) as D
order by constr, country, region, city 






select * from dbo.Orders
select IS_NULLABLE, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME='Employees' and IS_NULLABLE='YES'

select TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS
where DATA_TYPE like '%[D,d]ate%';