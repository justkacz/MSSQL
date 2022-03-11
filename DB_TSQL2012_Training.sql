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
from [HR].[Employees] 

--DATA RANGE FILTERING:
--in most cases, when you apply manipulation on the filtered column, SQL Server cannot use an index in an efficient manner:
--INSTEAD OF:
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2007;

--BETTER WAY: (you need to revise the predicate so that there is no manipulation on the filtered column)
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20070101' AND orderdate < '20080101';

select cast(sysdatetime() as date) as data,
	   cast(sysdatetime() as time) as czas,
	   CONVERT(varchar, SYSDATETIME(),	108) as format_czas





select IS_NULLABLE, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS 
where TABLE_NAME='Employees' and IS_NULLABLE='YES'

select TABLE_NAME, COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS
where DATA_TYPE like '%[D,d]ate%';