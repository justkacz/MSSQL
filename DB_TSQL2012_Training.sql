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

--Any data type without the VAR element (CHAR, NCHAR) in its name has a fixed length, which means that SQL Server preserves space in the row based on the column’s defined size and not on
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
-- if the wildcard character belongs to %, _,[ the square brackets might be used instead of escape character: LIKE ‘%[_]%’




--******************************************************************************************DATE/TIME:
--IMPLICIT CONVERSIONS - are not visible to the user. SQL Server automatically converts the data from one data type to another. according to the rules of datatype precedence.
--EXPLICIT CONVERSIONS -  if you don’t specify how SQL Server should convert the data types to do what you want (explicitly), it will try to guess your intentions (implicitly), (use the CAST or CONVERT functions)

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


-- TRY_CAST, TRY_CONVERT, and TRY_PARSE: if the input isn’t convertible to the target type, the function returns a NULL instead of failing the query.

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
--Also return customers who didn’t place orders on February 12, 2007:

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

--creating new table Orders:
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


-- running aggregation (as an alternative to window function):
select top 5 * from [Sales].[OrderTotalsByYear]

select orderyear, qty, 
		(select SUM(qty)
		from [Sales].[OrderTotalsByYear] O2
		where O2.orderyear<=O1.orderyear) running_qty
from [Sales].[OrderTotalsByYear] O1
order by orderyear




select * from dbo.Orders
select IS_NULLABLE, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME='Employees' and IS_NULLABLE='YES'

select TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS
where DATA_TYPE like '%[D,d]ate%';