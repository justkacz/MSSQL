--*********************************************DATABASE AND TABLE:
--database TSQL2012 available : https://raw.githubusercontent.com/justkacz/MSSQL/main/DataBase_TSQL2012.sql

create database WinFin
drop table WinFun

select *
into OrderDetails
from TSQL2012.Sales.OrderDetails

select *
into Orders
from TSQL2012.Sales.Orders

select o.*, od.productid, od.unitprice, od.qty, od.discount
, od.qty * od.unitprice as val
into OrdDet
from Orders o
join OrderDetails od
on o.orderid=od.orderid

select  
from [Sales].[Orders]
select * from [Sales].[OrderDetails]

select * from Orders
select * from OrderDetails

select * from OrdDet

