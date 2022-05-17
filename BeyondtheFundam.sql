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
		lead(val, 1, 0) over(partition by custid order by orderdate, orderid)as next_val --third argument specifies the value which should replace NULL
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
-- identity column might be quered not only by the columns name but also using $identity:

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


-- MERGING DATA:
-- merge the contents of the CustomersStage table (the source) into the Customers table (the target).
-- target table name (BASE TABLE) in the MERGE clause and the source table name in the USING clause

IF OBJECT_ID('dbo.CustomersMerge', 'U') IS NOT NULL DROP TABLE dbo.CustomersMerge;
GO
CREATE TABLE dbo.CustomersMerge
(
custid INT NOT NULL,
companyname VARCHAR(25) NOT NULL,
phone VARCHAR(20) NOT NULL,
address VARCHAR(50) NOT NULL,
CONSTRAINT PK_CustomersMerge PRIMARY KEY(custid)
);

INSERT INTO dbo.CustomersMerge(custid, companyname, phone, address)
VALUES
(1, 'cust 1', '(111) 111-1111', 'address 1'),
(2, 'cust 2', '(222) 222-2222', 'address 2'),
(3, 'cust 3', '(333) 333-3333', 'address 3'),
(4, 'cust 4', '(444) 444-4444', 'address 4'),
(5, 'cust 5', '(555) 555-5555', 'address 5');

IF OBJECT_ID('dbo.CustomersStageM', 'U') IS NOT NULL DROP TABLE dbo.
CustomersStageM;
GO
CREATE TABLE dbo.CustomersStageM
(
custid INT NOT NULL,
companyname VARCHAR(25) NOT NULL,
phone VARCHAR(20) NOT NULL,
address VARCHAR(50) NOT NULL,
CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);
INSERT INTO dbo.CustomersStageM(custid, companyname, phone, address)
VALUES
(2, 'AAAAA', '(222) 222-2222', 'address 2'),
(3, 'cust 3', '(333) 333-3333', 'address 3'),
(5, 'BBBBB', 'CCCCC', 'DDDDD'),
(6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
(7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

-- query that merges the contents of the CustomersStageM table (the source, table from which the data will be uploaded) into the CustomersMerge table (the target, table that will be updated)
-- (add customers who does not exist and update the attributes of customers that already exist)
-- = target table will be updated with records from the source table

MERGE INTO dbo.CustomersMerge as TGT
using CustomersStageM as SRC
ON TGT.custid = SRC.custid
when matched then
	update set
	TGT.companyname = SRC.companyname,
	TGT.phone = SRC.phone,
	TGT.address = SRC.address
when not matched then
	insert (custid, companyname, phone, address)
	values (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN										-- all id numbers which do not appear in the source table will be deleted from the final output 
DELETE;

select * from dbo.CustomersMerge

-- above statement updates all items independently also if they are the same in both tables - below query updates only different elements (optimized solution):
MERGE dbo.CustomersMerge as TGT
	using CustomersStageM as SRC
		on TGT.custid = SRC.custid
when matched and
	(TGT.companyname <> SRC.companyname OR
	TGT.phone <> SRC.phone OR
	TGT.address <> SRC.address) then
		update set
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
when not matched then
	insert(companyname, phone, address)
	values(SRC.companyname, SRC.phone, SRC.address);


select * from CustomersMerge

-- MODIFYING DATA THROUGH TABLE EXPRESSIONS:
-- not only SELECT but also another DML statements (INSERT, UPDATE, DELETE, and MERGE) are allowed against table expressions
-- RESTRICTIONS:
-- * If query defining the table expression joins tables, in the same modification statement only one of the sides of the join
--   allowed to affect
-- * column that is a result of the calculation cannot be updated, 
-- * INSERT statements must specify values for any columns in the underlying table that do not have implicit values. A column can get a value implicitly if it allows NULL marks, has a default
-- value, has an identity property, or is typed as ROWVERSION.

-- query that updates columns after join: 
select top 5 * from Sales.OrderDetails
select top 5 * from dbo.Orders

update OD
	set discount += 0.05
from Sales.OrderDetails OD
	join dbo.Orders O
		on OD.orderid = O.orderid
where O.custid =1

-- or using CTE - update statement relates to the CTE alias:

with C
as (
	SELECT O.custid, OD.orderid, OD.productid, OD.discount, OD.discount + 0.05 AS newdiscount
	from Sales.OrderDetails OD
	join dbo.Orders O
		on OD.orderid = O.orderid 
)
update C
	set discount=newdiscount

-- or using a derived table (aliases created in derived table can be used in the outer statement):
update D
	set discount=newdiscount	
from (SELECT
	O.custid, OD.orderid, OD.productid, OD.discount, OD.discount + 0.05 AS newdiscount
	from Sales.OrderDetails OD
	join dbo.Orders O
		on OD.orderid = O.orderid
	where O.custid=1
) as D;

-- an example where CTE is only possible solution:
if OBJECT_ID('dbo.T1') is not null drop table dbo.T1;

create table dbo.T1 (col1 INT, col2 INT);
go

insert into dbo.T1(col1) values (10),(20),(30);
select * from T1

-- query that updates col2 as a result of an expression with the ROW_NUMBER() function:
update T1
	set col2 = ROW_NUMBER() over(order by col1)  -- error -> WINDOW FUNCTIONS can only appear in the SELECT or ORDER BY clause

-- the only solution using CTE:
with C
as 
(
	Select col1, col2, ROW_NUMBER() over(order by col1) as rownum
	from  T1
)
update C
	set col2=rownum

select * from T1

-- MODIFICATIONS with TOP and OFFSET-FETCH:
-- * ORDER BY cannot be used for the TOP option with modification
-- DELETE TOP(50) FROM dbo.Orders -> will delete random items, without preserving any order

-- using CTE as a solution:
-- new table for testing:
create table dbo.OrdDetMerge (
	orderid INT NOT NULL,
	custid INT NULL,
	empid INT NOT NULL,
	orderdate DATETIME NOT NULL,
	requireddate DATETIME NOT NULL,
	shippeddate DATETIME NULL,
	shipperid INT NOT NULL,
	freight MONEY NOT NULL
		CONSTRAINT DFT_Orders3_freight DEFAULT(0),
	shipname NVARCHAR(40) NOT NULL,
	shipaddress NVARCHAR(60) NOT NULL,
	shipcity NVARCHAR(15) NOT NULL,
	shipregion NVARCHAR(15) NULL,
	shippostalcode NVARCHAR(10) NULL,
	shipcountry NVARCHAR(15) NOT NULL,
		CONSTRAINT PK_Orders3 PRIMARY KEY(orderid)
);
insert into dbo.OrdDetMerge
select * from [Sales].[Orders]

with C
as
(
	select top(50) *
	from dbo.OrdDetMerge
	order by orderid
)
delete from C

select * from dbo.OrdDetMerge

-- query that updates the 50 orders with the highest order ID values, increasing their freight values by 10:
with C
as
(
	 select top (50) *
	 from dbo.OrdDetMerge
	 order by orderid desc
)
update C
	set freight+=10

-- offset-fetch instead of
with C
as
(
	 select *
	 from dbo.OrdDetMerge
	 order by orderid desc
	 offset 0 rows
	 fetch FIRST 50 rows only
)
delete from C

-- OUTPUT clause:
-- allows to define the attributes and expressions that should be returned:
-- * INSERT -> inserted
-- * DELETE -> deleted
-- * UPDATE -> inserted to see new rows, deleted to see changed rows

with C
as
(
	select top (5) *
	from dbo.OrdDetMerge
	order by orderid desc	
)
delete from C
output deleted.custid, deleted.orderid --without this clause, as an output would be only the number of rows affected

-- update with output:
update dbo.OrdDetMerge
	set freight+=10
output 
	inserted.orderid as orderid,
	deleted.freight as oldfreight,
	inserted.freight as newfreight
where custid=51

-- creating new table to store output results with changes:
create table dbo.ProductsAudit(
productid int,
colname varchar(20), 
oldval varchar(20), 
newval varchar(20))



INSERT INTO dbo.ProductsAudit(productid, colname, oldval, newval)
select c_id, theaction, oldcompanyname, newcompanyname
from(
MERGE INTO dbo.CustomersMerge as TGT
using CustomersStageM as SRC
ON TGT.custid = SRC.custid
when matched then
	update set
	TGT.companyname = SRC.companyname,
	TGT.phone = SRC.phone,
	TGT.address = SRC.address
when not matched then
	insert (custid, companyname, phone, address)
	values (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
output 
$action AS theaction, 
inserted.custid as c_id,
deleted.companyname AS oldcompanyname,
inserted.companyname AS newcompanyname,
deleted.phone AS oldphone,
inserted.phone AS newphone,
deleted.address AS oldaddress,
inserted.address AS newaddress) as M;

select * from dbo.ProductsAudit

-- table for below exercises:
IF OBJECT_ID('dbo.CustomersExc', 'U') IS NOT NULL DROP TABLE dbo.CustomersExc;
CREATE TABLE dbo.CustomersExc
(
custid INT NOT NULL PRIMARY KEY,
companyname NVARCHAR(40) NOT NULL,
country NVARCHAR(15) NOT NULL,
region NVARCHAR(15) NULL,
city NVARCHAR(15) NOT NULL);

insert into CustomersExc values(100, 'Coho Winery', 'USA', 'WA', 'Redmond')

-- query that inserts into the dbo.Customers table all customers from Sales.Customers who placed orders:

insert into CustomersExc
select custid, companyname, country, region, city
from Sales.Customers C
where exists (select *
			from [Sales].[Orders] O
			where C.custid=O.custid)


--SELECT INTO statement to create and populate the dbo.Orders4 table with orders from the Sales.Orders table that were placed in the years 2006 through 2008
-- 1) orders which were placed between 2006 and 2008:

Select *
into dbo.Orders4 -- a new table does not have to be created earlier
from [Sales].[Orders]
	where orderdate >= '20060101' and orderdate < '20080101'

Select * from Orders4

--Delete from the dbo.Orders table orders placed by customers from Brazil.
select top 5 * from dbo.Orders
select top 5 * from [Sales].[Customers]


delete from dbo.Orders
where exists (select * 
			from [Sales].[Customers] C
			where Orders.custid=C.custid
			and country = 'Brazil')

-- or using delete syntax based on join:
delete from O
from dbo.Orders as O
	join [Sales].[Customers] C   --join serves as a filtering purpose
		on C.custid=O.custid
where country = 'Brazil'

-- or using merge statement:

merge dbo.Orders TRG
using [Sales].[Customers] SRC
	on SRC.custid=TRG.custid
when matched then delete;

-- query that updates the dbo.Customers table and changes all NULL region values to <None>. Then the OUTPUT clause must be used to show the custid, oldregion, and newregion
select * from [dbo].[Customers]

update [dbo].[Customers]
	set region = '<None>'
output
deleted.custid as custid, 
deleted.region as oldregion,
inserted.region as newregion
where region is null

-- query that updates all orders in the dbo.Orders table that were placed by United Kingdom customers and sets their shipcountry, shipregion, and shipcity values to the country, region, and city values of the corresponding customers
select *
into dbo.Orders5 
from [dbo].[Orders4]

select top 5 * from [dbo].[Orders5]
select top 5 * from [dbo].[Customers]

select * from [dbo].[Orders5] O
join [dbo].[Customers] C
on O.custid=C.custid
where C.country='UK'



merge into [dbo].[Orders5] TRG
using [dbo].[Customers] SRC
on TRG.custid=SRC.custid and SRC.country='UK'
when matched then 
	update set
	TRG.shipcountry=SRC.country,
	TRG.shipcity=SRC.city,
	TRG.shipregion=SRC.region

output
deleted.shipcountry as oldcountry,
deleted.shipcity as oldcity,
deleted.shipregion as oldregion,
inserted.shipcountry as newcountry,
inserted.shipcity as newcity,
inserted.shipregion as newregion;

-- or by using update solution based on join;
update O	
	set 
	shipcountry = C.country,
	shipregion = C.region,
	shipcity = C.city
from [dbo].[Orders5] O
	join [dbo].[Customers] C
		on O.custid=C.custid
where C.country='UK'

-- or by using CTE
with  CTE_UP
as
(	select O.shipcountry AS ocountry, C.country AS ccountry,
			O.shipregion AS oregion, C.region AS cregion,
			O.shipcity AS ocity, C.city AS ccity
	from [dbo].[Orders5] O
	join [dbo].[Customers] C
		on O.custid=C.custid
	where C.country='UK'
)
update CTE_UP
set ocountry=ccountry, ocity=ccity, oregion=cregion;


-- ***************************************************************************TRANSACTIONS AND CONCURRENCY:
-- TRANSACTION is a unit of work that might include multiple activities that query and modify data and that can also change data definition.
--BEGIN TRAN (or TRANSACTION) -> COMMIT TRAN or ROLLBACK TRAN (or TRANSACTION) - if transaction should not be commited

-- IMPLICIT_TRANSACTIONS - by default OFF, changing to ON allows to start transaction without BEGIN TRAN keywords, but the transaction's end must be marked with commit or rollback

-- ACID properties: 
-- *  atomicity - if errors are encountered during the transaction before the commit statement, all changes are not considered and undone
--				(exception:  primary key violation or lock expiration timeout)
-- *  consistency
-- *  isolation - control access: if the data is in the level of consistency that those transactions expect (locking - default in an on premises server, readers require shared locks; row versioning - shared locks are not required, if the current state of
--             the data is inconsistent, the reader gets an older consistent state)
-- *  durability - data changes are always written to the database’s transaction log on disk before they are written to the data portion of the database on disk, When the system starts, either normally or after a system failure, SQL Server inspects the transaction log of each database and runs a
-- recovery process with two phases—redo and undo

-- LOCKS - are control resources obtained by a transaction to guard data resources, preventing conflicting or incompatible access by other transactions.
-- two main models: exclusive (if one transaction modifies rows, until the transaction is completed, another transaction cannot modify the same rows) and shared (multiple transactions can hold shared locks on the same data resource simultaneously):

-- READ COMMITTED isolation level, if a transaction modifies rows, until the transaction completes, another transaction can’t read the same rows

--SUMMARY: data that was modified by one transaction can neither be modified nor read (at least by default in an on-premises SQL Server installation) by another transaction until the first transaction finishes. And while data is
-- being read by one transaction, it cannot be modified by another (at least by default in an on-premises SQL Server installation)