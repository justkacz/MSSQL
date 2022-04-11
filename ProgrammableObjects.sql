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

-- IF...ELSE IF...ELSE:
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
DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);

set @cols = STUFF((SELECT distinct ',' + c.shipcountry
            FROM [Sales].[Orders] c
            FOR XML PATH('')),1,1,'')

--STUFF function - replaces characters; 
-- without stuff the result of SELECT distinct ',' + c.shipcountry FROM [Sales].[Orders] c FOR XML PATH('') would be one row with distinct shipcountries separated with comma and with a comma mark as the first character
-- STUFF - 1st argument => string to be replaced; 2nd => starting point; 3rd => the number of characters to be deleted; 4th => new replacing character

set @query = 'SELECT * from 
            (select shipperid
                    , freight
                    , shipcountry
                from [Sales].[Orders]
           ) x
            pivot 
            (
                 sum(freight)
                for shipcountry in (' + @cols + ')
            ) p 
			order by shipperid'

execute(@query)

-- ROUNTINES: objects that encapsulate code to calculate a result or to execute activity => USER DEFINED FUNCTIONS, STORED PROCEDURES, TRIGGERS
--USER DEFINED FUNCTIONS: scalar and table-valued (can appear only in the from clause) UDFs

-- function that returns the age of a person with a specified birthday at a specified event date
create function dbo.getAge
(
	@birthdate as date,
	@eventdate as date
)
returns int
as 
	begin
		return
			datediff(YEAR, @birthdate, @eventdate)
				-case												-- if the @eventdate occurs before birthdate we need to substruct 1 
					when 100 * month(@birthdate) + day(@birthdate)
					< 100 * month(@eventdate) + day(@eventdate)
					then 0 else 1
				 end	
	end

select empid, firstname, lastname, birthdate, dbo.getAge(birthdate, sysdatetime()) as age
from [HR].[Employees]

-- STORED PROCEDURES:
-- can have input and output parameters, 
-- can return result sets of queries, and  are allowed to invoke code that has side effects
-- stored procedure altered in one place in the database will be changed for all users of the procedure
-- additional, separate authorizations might be granted

-- stored procedure that returns orders placed by the declared customerid between two dates:
if OBJECT_ID('Sales.GetCustomerOrders') is not null drop procedure Sales.GetCustomerOrders
go

create procedure Sales.GetCustomerOrders
	@custid as int,
	@fromdate as datetime,
	@todate as datetime,
	@rownum as int output -- output parameter
as
set nocount on -- will show how many rows were affected

	select orderid, custid, empid, orderdate
	from [Sales].[Orders]
		where custid=@custid
		and orderdate>=@fromdate
		and orderdate<@todate

set @rownum= @@ROWCOUNT -- built in global variable
go

-- execution of the procedure:
declare @rc as int
exec Sales.GetCustomerOrders
@custid=1,
@fromdate = '20070101',
@todate = '20080101',
@rownum = @rc OUTPUT;

SELECT @rc AS numrows;


--TRIGGER:
-- a special kind of stored procedure, 
-- whenever the event takes place, the trigger fires and the trigger’s code runs
-- ROLLBACK TRAN within the trigger’s code causes a rollback of all changes that took place in the trigger, and also of all changes that took place in the transaction associated with the trigger
-- function EVENTDATA  returns the event information as an XML value


-- DML Triggers:
-- * after -> after associated event finishes, only on permanent tables
-- * instead of -> fires instead of the event it is associated with, permanent tables and views
-- in the trigger’s code, you can access tables called INSERTED and DELETED that contain the rows that were affected by the modification that caused the trigger to fire.
--  path: database > table (followed by ON in the trigger definition) > folder: Triggers

IF OBJECT_ID('dbo.T3_Audit', 'U') IS NOT NULL DROP TABLE dbo.T3_Audit;
IF OBJECT_ID('dbo.T3', 'U') IS NOT NULL DROP TABLE dbo.T3;

CREATE TABLE dbo.T3
(
	keycol INT NOT NULL PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
);
CREATE TABLE dbo.T3_Audit
(
	audit_lsn INT NOT NULL IDENTITY PRIMARY KEY,
	dt DATETIME NOT NULL DEFAULT(SYSDATETIME()),
	login_name sysname NOT NULL DEFAULT(ORIGINAL_LOGIN()),
	keycol INT NOT NULL,
	datacol VARCHAR(10) NOT NULL
);
go

-- trigger inserts new records to the T3_Audit table if any new row is inserted into the original table T3:
create trigger tgrT3 on dbo.T3 after insert
as
	set nocount on
insert into dbo.T3_Audit(keycol, datacol)
select keycol, datacol from inserted -- inserted = records inserted into T3 table
go

insert into T3 values (1,'a')
insert into T3 values (2,'b')
insert into T3 values (3,'c')
insert into T3 values (4,'d')

select * from T3
select * from T3_Audit

-- DDL TRIGGERS:
-- at the database scope (e.g. create table) or the server scope (e.g. create database)
-- supports only AFTER event (INSTEAD OF is not available)
-- path: database > folder: Programmability > Database Triggers 

IF OBJECT_ID('dbo.AuditDDLEvents', 'U') IS NOT NULL DROP TABLE dbo.AuditDDLEvents;

CREATE TABLE dbo.AuditDDLEvents
(
	audit_lsn INT NOT NULL IDENTITY,
	posttime DATETIME NOT NULL,
	eventtype sysname NOT NULL,
	loginname sysname NOT NULL,
	schemaname sysname NOT NULL,
	objectname sysname NOT NULL,
	targetobjectname sysname NULL,
	eventdata XML NOT NULL,
	CONSTRAINT PK_AuditDDLEvents PRIMARY KEY(audit_lsn)
);


create trigger trg_ddl on database for DDL_DATABASE_LEVEL_EVENTS -- = event group that represents all DDL events on database level
as
	set nocount on
	declare @eventdata as xml = eventdata()
	insert into dbo.AuditDDLEvents(
		posttime, eventtype, loginname, schemaname,
		objectname, targetobjectname, eventdata)
	values (
		@eventdata.value('(/EVENT_INSTANCE/PostTime)[1]', 'VARCHAR(23)'),
		@eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname'),
		@eventdata.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'sysname'),
		@eventdata);
go

create table dbo.ddltest(col1 int not null)
alter table dbo.ddltest add col2 int null
alter table dbo.ddltest alter column col2 int not null

select * from AuditDDLEvents

-- ERROR HANDLING:
-- TRY...CATCH statement (together with BEGIN...END)
-- inbuilt functions: 
--		* ERROR_NUMBER()
--		* ERROR_MESSAGE()
--		* ERROR_LINE() - returns the line number when the error happened
--		* ERROR_PROCEDURE() - returns the name of the procedure in which the error happened
-- sys.messages - catalog view with a list of error numbers and messages

create procedure dbo.ErrorHandler
as
	PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
	PRINT 'Error Message : ' + ERROR_MESSAGE();
	PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
	PRINT 'Error State : ' + CAST(ERROR_STATE() AS VARCHAR(10));
	PRINT 'Error Line : ' + CAST(ERROR_LINE() AS VARCHAR(10));
	PRINT 'Error Proc : ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
go



begin try
	print 10/0   -- or 10/0 will run catch statement
	print 'No errors'
end try
begin catch
	print 'Error due to ' + lower(ERROR_MESSAGE())
	exec dbo.ErrorHandler
end catch

select * from sys.messages

