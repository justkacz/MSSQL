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
