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


-- FUNCTIONS OVERVIEW:

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

SELECT RTRIM('   AAA  II  I   ')+ 'XXX';