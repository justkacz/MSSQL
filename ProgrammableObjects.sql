-- BATCH -  is one T-SQL statement or more sent to SQL Server for execution as a single unit
-- A transaction is an atomic unit of work. A batch can have multiple transactions, and a transaction can be submitted in parts as multiple batches
-- GO cammand signals the end of a batch (is a client command and not a T-SQL server command)
-- A variable is local to the batch in which it is defined.


declare @empname as varchar(40)
set @empname = (select firstname + ' ' + lastname 
				from [HR].[Employees]
				where empid = 3)


-- variable might be declared without SET:
declare @empname2 as varchar(40) = (select firstname + ' ' + lastname 
				from [HR].[Employees]
				where empid = 3)

select @empname as employee_name

-- or two separate variables (SET statement can operate only on one variable at a time = for each variable separete set clause):
DECLARE @firstname varchar(10), @lastname varchar (10)

set @firstname = (select firstname
				from [HR].[Employees]
				where empid = 3)

set @lastname = (select lastname
				from [HR].[Employees]
				where empid = 3)

select @firstname +' ' + @lastname as emp_name

-- or:
declare @firstname varchar(10), @lastname varchar(10)

select 
	@firstname = firstname,
	@lastname = lastname
from [HR].[Employees]
where empid =2

select @firstname as firstname, @lastname as lastname

--SET statement is safer than assignment SELECT because it requires to use a scalar subquery to pull data from a table


-- The following statements cannot be combined with other statements in the same batch: 
-- CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE SCHEMA, CREATE TRIGGER, and CREATE VIEW

-- with IF statement:
if OBJECT_ID('Sales.MyView') is not null drop view Sales.MyView

create view Sales.MyView
as
SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate);
go -- error - 'CREATE VIEW' must be the first statement in a query batch -> solution: add second GO after IF statement


-- GO might be followed by the number indicating how many times batch should run:
if OBJECT_ID('dbo.T1') is not null drop table dbo.T1
create table dbo.T1 (col1 int)
go

set nocount on  -- provides the number of rows affected

insert into dbo.T1 default values -- without identity in column declaration table would be filled with NULLs
go 100

select * from T1

-- IF...ELSE...:
-- else is activated when the predicate is FALSE or UNKNOWN
-- multiple If/else statements the block statement must be declared: BEGIN ...END

-- code that checks whether today is the last day of the year:
print dateadd(day, 1, sysdatetime())

if year(SYSDATETIME()) <> YEAR(dateadd(day, 1, SYSDATETIME()))
	print 'Today is the last day of the year'
else 
	if MONTH(SYSDATETIME())<> MONTH(DATEADD(day, 1, sysdatetime()))
		print 'Today is not the last day of the year but the last day of the month'
	else
		print 'Today is neither the last day of the month nor the last day of the year'

-- multiple if/else statements:
if day(SYSDATETIME())=1
begin
	PRINT 'Today is the first day of the month.';
	PRINT 'Starting first-of-month-day process.';
	--the rest of code--
end
else
begin 
	PRINT 'Today is not the first day of the month.';
	PRINT 'Starting non-first-of-month-day process.';
end

-- WHILE:
declare @i int=1
while @i<=10
	begin
		print @i
		set @i+=1
	end

declare @i int = 0
while @i <=10
	begin
		set @i += 1
		if @i = 6 continue;
		print @i
	end

-- populating table columns using WHILE LOOP and IF:
if OBJECT_ID('dbo.Whiletest') is not null drop table dbo.Whiletest
create table dbo.Whiletest(col1 int not null, col2 int not null)
go

declare @i int =1
declare @j int=0

while @i <= 1000 and @j <=2000
	begin
		insert into dbo.Whiletest(col1, col2) values(@i, @j)
		set @i +=1
		set @j += 2
	end

select * from Whiletest

-- CURSORS = a nonrelational result with order guaranteed among rows
-- query with an ORDER BY clause (query without an ORDER BY statement returns set or multiset)

-- DRAWBACKS of using cursors:
-- * relational model is based on set theory
-- *  record by record processing is not efficient, cursor code is usually many times slower than the set-based code

-- When CURSORS are useful:
-- * when there is a need to apply a certain task to each row from some table or view
-- *  based solutions tend to be much faster, but in some cases the cursor solution is faster e.g. calculations that, if done by processing one row at a time in a certain order, involve much
--  less data access compared to the way the version of SQL Server you’re working with optimizes corresponding set-based solutions

-- TEMPORARY TABLES - created in tempdb database; :
-- * LOCAL temporary tables
-- * GLOBAL temporary tables
-- * TABLE VARIABLES

-- 1) LOCAL TEMPORARY TABLE: 
-- * is visible only to the session that created it

-- query that creates local temporary table where is stored the result showing the sum of quantity for the current and previous year
select top 5 * from [Sales].[Orders]
select top 5 * from [Sales].[OrderDetails]

if OBJECT_ID('tempdb.dbo.#MyOrderTotalsByYear') is not null drop table dbo.#MyOrderTotalsByYear

create table #MyOrderTotalsByYear(
	orderyear INT NOT NULL PRIMARY KEY,
	qty INT NOT NULL
)

insert into #MyOrderTotalsByYear(orderyear, qty)
	select year(O.orderdate), sum(OD.qty)
	from [Sales].[Orders] O
	join [Sales].[OrderDetails] OD
		on O.orderid=OD.orderid
	group by year(O.orderdate)

select Cur.orderyear, Cur.qty as currentq, Prev.qty as Prevq
from #MyOrderTotalsByYear Cur
	left join #MyOrderTotalsByYear Prev
		on Cur.orderyear = Prev.orderyear +1

SELECT orderyear, qty FROM dbo.#MyOrderTotalsByYear;  -- table available only to the current session

-- 2) GLOBAL TEMPORARY TABLE:
-- *  it is visible to all other sessions
-- *  destroyed automatically by SQL Server when the creating session disconnects and there are no active references to the table
-- *  useful when temporary data should be shared with others


create table dbo.##Global
(
	id sysname not null primary key, --sysname: the type that SQL Server uses internally to represent identifiers
	val SQL_VARIANT not null        -- SQL_VARIANT: a generic type taht can store almost any base type
)

insert into dbo.##Global (id, val) values ('i', CAST(10 as int))

select * from dbo.##Global  -- available also in new session, till connection is active

-- 3) TABLE VARIABLES (similar to local temporary table):
-- present in the temporary db: tempdb
-- visible only to the creating session, with more limited scope than local table: visible only in the current batch
-- if transaction completes; ROLLBACK statement does not undo changes (only if transaction fails or is terminated before completion)

-- query that returns the same result as above local temporary table but using table variable:

declare @MyOrderTotalsByYear table
(
	orderyear INT NOT NULL PRIMARY KEY,
	qty INT NOT NULL
)
insert into @MyOrderTotalsByYear
	SELECT YEAR(O.orderdate) AS orderyear, SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
		JOIN Sales.OrderDetails AS OD
			ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate);

select Cur.orderyear, Cur.qty, Prev.qty
from @MyOrderTotalsByYear Cur
 left join @MyOrderTotalsByYear Prev
	on Cur.orderyear=Prev.orderyear +1



-- DYNAMIC SQL:
-- allows to construct a batch of T-SQL code as a character string and then execute that batch by using EXEC or the sp_executesql stored procedure (is more secure and more flexible)
-- increases the chances for reusing a previously cached plan

-- EXEC:
declare @stat as varchar(100)
set @stat = 'PRINT ''This message was printed by a dynamic SQL batch.'''
exec(@stat)

--sp_executesql:
-- * has 2 input parameters and an assigment section:
--		@stms (statement parameter) => first parameter, holds the batch of code
--		@params => second parameter, holds the declarations of input and output parameters

declare @sql as nvarchar(100)

-- batch of code which will be held by the first parameter @stms => statement parameter
set @sql ='Select orderid, custid, empid, orderdate
			from Sales.Orders
			where orderid = @orderid'

exec sp_executesql
	@stmt =@sql,
	@params=N'@orderid as int',
	@orderid = 10249


-- PIVOT with DYNAMIC SQL:

-- an example of query using static pivot => VALUES SPECIFIED IN THE IN CLAUSE OF THE PIVOT OPERATOR MUST BE KNOWN AHEAD
select top 5 * from [Sales].[Orders]

select * from (
select shipperid, freight, YEAR(orderdate) as yearorder
	from [Sales].[Orders]) as D
pivot (sum(freight) for yearorder in ([2006],[2007],[2008])) as P 
order by shipperid

-- with dynamic query the years might be extracted by using DISTINCT:
DECLARE
	@sql AS NVARCHAR(1000),
	@orderyear AS INT,
	@first AS INT;

DECLARE C CURSOR FAST_FORWARD FOR
	SELECT DISTINCT(YEAR(orderdate)) AS orderyear
	FROM Sales.Orders
	ORDER BY orderyear;

SET @first = 1;
SET @sql = N'SELECT *
FROM (SELECT shipperid, YEAR(orderdate) AS orderyear, freight
FROM Sales.Orders) AS D
PIVOT(SUM(freight) FOR orderyear IN(';
OPEN C;

FETCH NEXT FROM C INTO @orderyear;
WHILE @@fetch_status = 0
BEGIN
	IF @first = 0
		SET @sql = @sql + N','
	ELSE
		SET @first = 0;
		SET @sql = @sql + QUOTENAME(@orderyear);
FETCH NEXT FROM C INTO @orderyear;
END
CLOSE C;
DEALLOCATE C;
SET @sql = @sql + N')) AS P;';
EXEC sp_executesql @stmt = @sql;

-- ROUNTINES: objects that encapsulate code to calculate a result or to execute activity => USER DEFINED FUNCTIONS, STORED PROCEDURES, TRIGGERS
--USER DEFINED FUNCTIONS: scalar and table-valued (can appear only in the from clause) UDFs
