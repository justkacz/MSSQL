--database script saved https://raw.githubusercontent.com/justkacz/MSSQL/main/DataBase_TSQL2012.sql

USE TSQL2012;

-- ALL AT-ONCE concept - there is no order of evaluation of the expressions in the SELECT list:

-- COLLATION - is a property of character data that encapsulates several aspects, including language support, ort order, case sensitivity, accent sensitivity, and more.
SELECT name, description
FROM sys.fn_helpcollations();


--Computing the number of occurences of the item put as an argument in the replace function:
select empid, lastname, len(lastname) - len(replace(lastname, 'e', '')) as num_occ
from HR.Employees


