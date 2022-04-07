--***********************************************WINDOW FUNCTIONS:
--computes a scalar result value based on a calculation against a subset of the rows from the underlying query. The subset of rows is known as a window
-- clause OVER, in which you provide the window specification
-- it performs a calculation against a set and returns a single value.
-- parts of the window specification in the OVER clause: partitioning, ordering and framing

--the starting point of a window function is the underlying query’s result set, and the underlying query’s result set is generated only when the SELECT phase is reached, window
-- functions are allowed only in the SELECT and ORDER BY clauses of a query. If there is a need to refer to a window function in an earlier logical query processing phase (such as WHERE), the table expression must be used
-- NTILE - divides the entire table on equal groups specified by the number of ntile 
-- DISTINCT in select clause does not work, first the unique row numbers are assigned then the distinct clause see that all rows are unique - > solution: using group by (it evaluates before select statement so unique row numbers are assigned to groups)


--query that uses a window aggregate function to compute the running total values for each employee and month
select top 5 * from [Sales].[EmpOrders]

select empid, ordermonth, val,
	SUM(val) over(partition by empid
					order by ordermonth
					rows between unbounded preceding and current row) as run_val
from [Sales].[EmpOrders]

-- using gruop by to achieve distinct values:
select val, ROW_NUMBER() over(order by val) as rownum
from [Sales].[OrderValues]
group by val   -- before select statement, rows are assigned to already grouped values



-- OFFSET WINDOW FUNCTION:
--allows to return an element from a row that is at a certain offset from the current row or from the beginning or end of a window frame
-- LAG() - looks BEFORE the current row, LEAD() - looks AHEAD the current row;  allows to obtain an element from a row that is at a certain offset from the current row within the partition, based on the indicated ordering, OFFSET as a second argument
-- FIRST_VALUE() + ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW, LAST_VALUE() + ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING - allows to return an element from the first and last rows in the window frame, respectively
-- ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING - 



-- query that returns previous/next customer's order value:
select top 5 * from Sales.OrderValues;

select custid, orderid, val, 
		isnull(lag(val) over(partition by custid order by orderdate, orderid), 0) as prev_val, --dealing with NULL values
		lead(val, 1, 0) over(partition by custid order by orderdate, orderid)as next_val --third argument specifies value which should replace NULL
from Sales.OrderValues;

-- query that returns a value of the first/last customer's order:
select custid, orderid, val, 
	FIRST_VALUE(val) over(partition by custid order by orderdate, orderid rows between unbounded preceding and current row) as first_val,
	last_value(val) over(partition by custid order by orderdate, orderid rows between current row and unbounded following) as last_val
from Sales.OrderValues
order by custid, orderdate, orderid

-- AGGREGATE WINDOW FUNCTIONS:
-- query against OrderValues that returns, along with each order, the grand total of all order values, as well as the customer total
select top 5 * from [Sales].[OrderValues]

select orderid, custid, val,
	SUM(val) over() as total_sum,
	sum(val) over(partition by custid) as total_cust --adding order by orderdate,orderid would result in running total for each customer
from [Sales].[OrderValues]

-- query that calculates for each row the percentage that the current value is of the grand total, and also the percentage that the current value is of the customer total:
select orderid, custid, val,
	cast(100*(val/SUM(val) over()) as numeric(5,2)) as total_perc,
	cast(100 * (val/sum(val) over(partition by custid)) as numeric(5,2)) as cust_perc,
	sum(val) over(partition by custid order by orderdate, orderid rows between 1 preceding and 2 following) -- the sum of one previous row, current row and two rows ahead
from [Sales].[OrderValues]

-- PIVOTING DATA - 3 logical phases involved:
-- * grouping phase with an associated grouping or on rows element,
-- * spreading phase with an associated spreading or on cols element,
-- * aggregation phase with an associated aggregation element and aggregate function

--****************************************CREATING TABLE dbo.Orders3:
if OBJECT_ID('dbo.Orders3', 'U') is not null drop table dbo.Orders3

create table dbo.Orders3
(
orderid INT NOT NULL,
orderdate DATE NOT NULL,
empid INT NOT NULL,
custid VARCHAR(5) NOT NULL,
qty INT NOT NULL,
CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

INSERT INTO dbo.Orders3(orderid, orderdate, empid, custid, qty)
VALUES
(30001, '20070802', 3, 'A', 10),
(10001, '20071224', 2, 'A', 12),
(10005, '20071224', 1, 'B', 20),
(40001, '20080109', 2, 'A', 40),
(10006, '20080118', 1, 'C', 14),
(20001, '20080212', 2, 'B', 12),
(40005, '20090212', 3, 'A', 10),
(20002, '20090216', 1, 'C', 20),
(30003, '20090418', 2, 'B', 15),
(30004, '20070418', 3, 'C', 22),
(30007, '20090907', 3, 'D', 30);

select top 5 * from [dbo].[Orders3]

-- query to produce a report with the total order quantity for each employee and customer:
select empid, custid, SUM(qty) as total_qty
from [dbo].[Orders3]
group by empid, custid

--PIVOTING WITH STANDARD SQL:
-- rows => defined in GROUP BY clause,
-- columns = spread => defined by CASE statement:

-- query that returns a pivot table with a total quantity for each employee (rows) and customer (columns):
select empid,
	sum(case when custid ='A' then qty end) as A,
	sum(case when custid ='B' then qty end) as B,
	sum(case when custid ='C' then qty end) as C,
	sum(case when custid ='D' then qty end) as D
from [dbo].[Orders3]
group by empid

-- PIVOTING with PIVOT OPERATOR: no need to specify group by - grouping elements are detected automatically as those which
-- have not been specified as either the spreading element or the aggregation element => so all the elements which are not used
-- as spreading or aggregation elements will be grouped -> table expressions to extract only needed elements

-- It is strongly recommend to never operate on the base table directly, even when the table contains only columns used as pivoting elements (there is a risk that additional columns will be added)

-- SELECT ...
-- FROM <source_table_or_table_expression>
--		PIVOT(<agg_func>(<aggregation_element>)
--			FOR <spreading_element>
--				IN (<list_of_target_columns>)) AS <result_table_alias>

select empid, A, B, C, D
from (select custid, empid, qty
		from [dbo].[Orders3]) as D
pivot(sum(qty) for custid in (A, B, C, D)) as P ;

-- with changed order:
select custid, [1], [2], [3] -- sqare brackets ensure column headers
	from (select empid, custid, qty
		from [dbo].[Orders3]) as D
	pivot(sum(qty) for empid in ([1], [2], [3])) as P


-- UNPIVOTING - is a technique to rotate data from a state of columns to a state of rows
--************************************************************CREATING A NEW TABLE:
IF OBJECT_ID('dbo.EmpCustOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpCustOrders;
CREATE TABLE dbo.EmpCustOrders
(
empid INT NOT NULL
	CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
A VARCHAR(5) NULL,
B VARCHAR(5) NULL,
C VARCHAR(5) NULL,
D VARCHAR(5) NULL
);

INSERT INTO dbo.EmpCustOrders(empid, A, B, C, D)
	SELECT empid, A, B, C, D
		FROM (SELECT empid, custid, qty
	FROM dbo.Orders3) AS D
		PIVOT(SUM(qty) FOR custid IN(A, B, C, D)) AS P;

SELECT * FROM dbo.EmpCustOrders;


--GROUPING SETS: defined by a simple aggregation query
-- SUBCLAUSES: 
-- a) GROUPING SETS - allows to define multiple grouping sets in the same query,
SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders3
GROUP BY
	GROUPING SETS
	(
		(empid, custid),
		(empid),
		(custid),
		()
	); 
	
-- b) CUBE - provides an abreviated way to define mulitple grouping sets 
-- CUBE(a,b,c) = GROUPING SETS( (a, b, c), (a, b), (a, c), (b, c), (a), (b), (c), () )

select empid, custid, SUM(qty)
from dbo.Orders3
group by cube(empid, custid)

-- c) ROLLUP - also provides an abbreviated way to define multiple grouping sets. However, unlike the CUBE subclause, ROLLUP doesn’t produce all possible grouping
-- sets that can be defined based on the input members—it produces a subset of those.
-- ROLLUP(a, b, c) = GROUPING SET((a,b, c), (a, b), (a), ())

-- GROUPING FUNCTION - accepts a name of a column and returns 0 if it is (!!!) a member of the current grouping set and 1 otherwise 
SELECT
	GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders3
GROUP BY CUBE(empid, custid);

-- GROUPING_ID FUNCTION - returns an integer bitmap in which each bit represents a different input element

-- query against the dbo.Orders3 table that computes for each customer order both a rank and a dense rank, partitioned by custid and ordered by qty.
select top 5 * from [dbo].[Orders3]

select orderid, orderdate, empid, custid, qty,
	RANK() over (partition by custid order by qty) as rank,
	dense_RANK() over (partition by custid order by qty) as d_rank
from [dbo].[Orders3]

-- query that computes for each customer order both the difference between the current order quantity and the customer’s previous order quantity and the
-- difference between the current order quantity and the customer’s next order quantity
select top 5 * from [dbo].[Orders3]

select orderid, orderdate, empid, custid, qty,
	qty-lag(qty) over (partition by custid order by orderdate, orderid) as diff_prev,
	qty-lead(qty) over (partition by custid order by orderdate, orderid) as diff_next
from [dbo].[Orders3]

--query that returns a row for each employee, a column for each order year, and the count of orders for each employee and order year
select top 5 * from [dbo].[Orders3]

select empid,
	COUNT(case when YEAR(orderdate)='2007' then 1 end) as c2007c,
	COUNT(case when YEAR(orderdate)='2008' then 1 end) as c2008c,
	COUNT(case when YEAR(orderdate)='2009' then 1 end) as c2009c
from [dbo].[Orders3]
group by empid

-- or with native pivot operator:
select empid, [2007] as c2007, [2008] as c2008, [2009] as c2009
from (select empid, YEAR(orderdate) as orderyear 
		from [dbo].[Orders3]) as D1
	pivot(count(orderyear) for orderyear in([2007], [2008], [2009])) as P


-- query that returns the total quantities for each: (employee, customer, and order year), (employee and order year), and (customer and order year). Include a result
-- column in the output that uniquely identifies the grouping set with which the current row is associated
select top 5 * from [dbo].[Orders3]

select
	GROUPING(empid) as emp_g,
	GROUPING(custid) as cus_g,
	GROUPING(YEAR(orderdate)) as y_g,
	empid, custid, YEAR(orderdate) as year, SUM(qty) as tot_q
from [dbo].[Orders3]
group by cube(empid, custid, YEAR(orderdate))





--********************************************************************************DATA MODIFICATIONS:
--query that creates a STORED PROCEDURE called Sales.usp_getorders, returning orders that were shipped to a specified input country

create proc Sales.usp_getorders 
	@country as nvarchar(40)
as

select orderid, orderdate, empid, custid
from [Sales].[Orders]
where shipcountry=@country

exec Sales.usp_getorders @country='France'

-- SELECT INTO: copies from the source the base structure (column names, types, nullability, and identity property) and the data. There are four things that the statement does not copy from the source: constraints, indexes,
-- triggers, and permissions

-- BULK INSERT: inserts the content of the file into the table:

create table bulktest2 (
	PK int not null identity(1,1),
	A varchar(10), 
	B varchar(10),
	C varchar(10))

BULK INSERT dbo.bulktest FROM 'C:\Users\--file path --\tsql.txt' --identity column with PK is defined, the comma is added as the first item in each line
WITH
(
DATAFILETYPE = 'char',
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n'
);

--INDENTITY & SEQUENCE - allows to automatically generate keys:
--identity (start value, step)
-- identity column might quered not ony by the columns name but also using $identity:

select $identity from bulktest;

-- returns the last identity value:
--SCOPE_IDENTITY  - value generated by the session in the current scope
--IDENT_CURRENT (table name as function) - regardless of the session in which it was produced
select SCOPE_IDENTITY() as scope_ident, --NULL because no identity values were created in the session in which this query ran
		IDENT_CURRENT ('bulktest') as ident_curr


--Even though the insert fails, the current identity value in the table will change


--SEQUENCE - alternative key-generating mechanism for identity, unlike identity it is not tied to a particular column in a particular table
-- use one sequence object that will help you maintain keys that would not conflict across multiple tables
-- allows to specify MIN/MAX values


-- DELETING DATA:
-- new table Customers:
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers
(
custid INT NOT NULL,
companyname NVARCHAR(40) NOT NULL,
contactname NVARCHAR(30) NOT NULL,
contacttitle NVARCHAR(30) NOT NULL,
address NVARCHAR(60) NOT NULL,
city NVARCHAR(15) NOT NULL,
region NVARCHAR(15) NULL,
postalcode NVARCHAR(10) NULL,
country NVARCHAR(15) NOT NULL,
phone NVARCHAR(24) NOT NULL,
fax NVARCHAR(24) NULL,
CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

CREATE TABLE dbo.Orders
(
orderid INT NOT NULL,
custid INT NULL,
empid INT NOT NULL,
orderdate DATETIME NOT NULL,
requireddate DATETIME NOT NULL,
shippeddate DATETIME NULL,
shipperid INT NOT NULL,
freight MONEY NOT NULL
CONSTRAINT DFT_Orders_freight DEFAULT(0),
shipname NVARCHAR(40) NOT NULL,
shipaddress NVARCHAR(60) NOT NULL,
shipcity NVARCHAR(15) NOT NULL,
shipregion NVARCHAR(15) NULL,
shippostalcode NVARCHAR(10) NULL,
shipcountry NVARCHAR(15) NOT NULL,
CONSTRAINT PK_Orders2 PRIMARY KEY(orderid),
CONSTRAINT FK_Orders_Customers FOREIGN KEY(custid)
REFERENCES dbo.Customers(custid)
);


insert into dbo.Orders
select * from [Sales].[Orders]

insert into dbo.Customers
select * from [Sales].[Customers]

--delete - deletes rows from a table with filter (in the where clause), does not reset the identity value back to the original seed
--truncate - deletes whole rows from a table, no ability to precise filter statement (more efficient comparing to delete), can be ROLLBACKED, resets the identity value back to the original seed,
--drop - deletes the whole table

--to prevent deleting or truncating table in the production environment the dummy table might be created with a foreign key pointing to the production table.
--(then the foreign key might be disabled)

-- to drop a table with the foreign key reference:
-- 1)  firstly drop the parent table then the child table OR
-- 2) drop the foreign key relations:
SELECT * 
FROM sys.foreign_keys
WHERE referenced_object_id = object_id('Customers')

select OBJECT_Name(158623608) --checking a name of the table with a number of parent_object_id provided in above statement

ALTER TABLE dbo.Orders  -- deleting foreign key which refers to the Customer table, and now the Customer table might be dropped
DROP CONSTRAINT FK_Orders_Customers;  
GO 

-- DELETE based on a JOIN:
-- query that deletes orders placed by customers from the United States:
delete from O
from [dbo].[Orders] as O   -- FROM clause id the first statement processed logically
	 join [dbo].[Customers] as C
	 on C.custid=O.custid
	where C.country = 'USA'


-- or using subqueries instead of join:
delete from [dbo].[Orders]
where exists (select * 
				from [dbo].[Customers] C
				where Orders.custid=C.custid
				and C.country = 'USA')

-- UPDATE TABLE:
-- ALTER Command is used to add, delete, modify the attributes of the tables, UPDATE is used to update existing records in a database
select top 5 * from [Sales].[OrderDetails]

update [Sales].[OrderDetails]
set discount += 0.05
where productid=51

select productid, discount from [Sales].[OrderDetails]
where productid=51 and discount = 0.050


-- UPDATE based on a JOIN:
--query that increases the discount of all order details of orders placed by customer 1 by 5 percent:
select top 5 * from [Sales].[OrderDetails]
select top 5 * from [Sales].[Orders]

update OD
set OD.discount += 0.05
from [Sales].[OrderDetails] OD
	join [Sales].[Orders] O
	on OD.orderid=O.orderid
where O.custid = 1

-- or the same result using subquery:
update [Sales].[OrderDetails]
set discount += 0.05
where exists (
	select * 
	from [Sales].[Orders]
	where custid = 1)

