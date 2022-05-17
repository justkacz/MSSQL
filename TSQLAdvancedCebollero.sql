--AdventureWorks2019 DB
-- Begin...End statement -> creates a block of code but does not define its scope; the variables defined inside this statement are available also outside
declare @order varchar(20) = 'descending';

if @order='ascending'
begin
	select 
	FirstName, 
	LastName, 
	MiddleName
	from [Person].[Person]
	order by lastname asc
end	
else if @order='descending'
begin
	select 
	FirstName, 
	LastName, 
	MiddleName
	from [Person].[Person]
	order by lastname desc
end
else
print 'Incorrect input!'

-----------------------------------
declare @i int =1

while @i<10
begin
	print @i;
	set @i = @i+1
end

--WAITFOR - delay:
print 'The first part';
go

declare @delay varchar(20);
select @delay='00:00:03'
waitfor delay @delay
print 'The second part after 3 seconds'


--pivot table that summarizes the total due amount for each region in US:
select CountryRegionCode,
		sum(case when Name= 'Central' then soh.totaldue else 0 end) as Central,
		sum(case when Name= 'Northeast' then soh.totaldue else 0 end) as Northeast,
		sum(case when Name= 'Northwest' then soh.totaldue else 0 end) as Northwest,
		sum(case when Name= 'Southeast' then soh.totaldue else 0 end) as Southeast,
		sum(case when Name= 'Southwest' then soh.totaldue else 0 end) as Southwest
--		select *
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory t
ON soh.TerritoryID = t.TerritoryID
	where CountryRegionCode='US'
group by CountryRegionCode


-- CHOOSE function - allows to choose element from a list
select PhoneNumberTypeID,
	CHOOSE(PhoneNumberTypeID, 'Phone1', 'Phone2', 'Phone3') --the first argument is index value (must be int decimal will be converted to int)
FROM Person.Person p
JOIN Person.PersonPhone pp
ON p.BusinessEntityID = pp.BusinessEntityID


--UDF:
-- PRINT, INSERT, UPDATE, MERGE i DELETE are not allowed

--radius function
create function radius(@r int)
returns int
WITH RETURNS NULL ON NULL INPUT		--optimization -> if any of the argument is null the function body is not executed
begin
	return PI()*POWER(@r, 2)
end

select dbo.radius(10)

--SCHEMABINDING - might increase the effectiveness of UDF even though it does not refer to any db object

--------------------------------
create function silnia(@n int=1)
returns decimal(38,0)
with returns null on null input
begin
	return
	(case
		when @n<=0 then null
		when @n>1 then @n * dbo.silnia(@n-1)
		when @n=1 then 1		-- important restriction, allows to avoid infinite loop (SQL Server allows to max 32 recurences)
	end)
end


select dbo.silnia(34)

-- or using function with nested CTE:
--recursive CTE:
with liczby(lic)
as
(
	select 1
	union all
	select lic+1
	from liczby
	where lic<5
)
select * from liczby

create function silnia2(@n int =1)
returns float
begin
	declare @wynik float
	set @wynik=NULL;  --returns null for @n<=0

	if @n>0
	begin
		with liczby(lic)
		as
		(
			select 1
			union all
			select lic+1
			from liczby
			where lic<@n
		)
		select @wynik=@wynik*lic
		from liczby
	end
	return @wynik
end

select dbo.silnia2(0)

-- MULTISTATEMENT TVS:
-- * RETURNS NULL ON NULL INPUT oraz CALLED ON NULL INPUT -> not available
-- * no variables or values after RETURN statement

drop table if exists dbo.CTETab

create table dbo.CTETab(num int not null primary key)
go
--filling CTETab with numbers from 1 to 30 000 (using CTE):

with NumCTE(n) 
as
(
	select 1
	union all
	select n+1
	from NumCTE
	where n<30000
)
insert into CTETab(num)
select * from NumCTE
option (maxrecursion 32000)

select * from CTETab

create function GetNumbers()
returns @result table
(	id int not null,
	SalesOrderID int NOT NULL,
	ProductID int NOT NULL,
	OrderQty int not null
)
begin 
insert into @result
(
	id,
	SalesOrderID,
	ProductID,
	OrderQty
)
select 
	c.num,
	o.ProductID,
	o.SalesOrderID,
	o.OrderQty
from CTETab c
	join Sales.SalesOrderDetail o
	ON c.num BETWEEN 1 AND o.OrderQty
return
end

select * from dbo.GetNumbers()

--  DETERMINISTIC FUNCTION -> every time returns the same value (with defined set of parameters or with no parameters)
-- NON-DETERMINISTIC FUNCTION -> every time might return different value (with the same set of parameters) e.g. RAND(), NEWID()
SELECT OBJECTPROPERTY (OBjECT_ID('dbo.silnia'), 'IsDeterministic'); --returns 0 = non-deterministic, 1 = deterministic

-- function that converts Fahrenheita to Celsius:
create function TempConv(@F decimal=1)
returns decimal
begin 
	return (@F-32)*(5.0/9.0)
end

select dbo.TempConv(120)

-- STORED PROCEDURES:
-- is a batch of statements grouped as a logical unit and stored in the database
-- a collection of Transact-SQL statements stored within the database, used to encapsulate queries, such as conditional statements, loops, and other powerful programming features
-- can return rows of data or single value
-- parameters with default value -> does not require keyword DEFAULT when procedure is called (as in case of UDF)
-- without RETURN at the end
-- parameters might be declared as OUTPUT (returns value from the procedure) or VARYING (only cursor parameters)

--NATIVE COMPILED STORED PROCEDURES - native compilation allows faster data access and more efficient query execution than interpreted (traditional) Transact-SQL, script is converted to C++ language and compiled once

-- STORED PROCEDURE vs FUNCTION:
-- stored procedure is more flexible to write any code that you want, while functions have a rigid structure and functionality
create function Text()
returns varchar(100)
begin
	return 'An example of function'
end

select dbo.Text()

create procedure Text2
as
print 'An example of sp'

exec Text2

-- the usage of function and stored procedure with another statements e.g. with concat():
select CONCAT(dbo.Text(), ', new concatenated part')

create procedure Text3
@text varchar(100) output  -- to use stored procedure as argument in the CONCAT function the output parameter is obligatory
as
select @text='An example of sp2'

declare @message varchar(100)
exec Text3 @text = @message output
select @message
select CONCAT(@message, ', new concatenated part')

-- invoking function from stored procedure:
create procedure Text4
as
select dbo.Text()

exec Text4

--stored procedure that returns order details from selected year
create procedure Totaldue 
@Year int
as
select *, replace(replace((x.runn_tot/x.Grand_total)*100, '0.00', 'too small value' ), '10too small value', '100.00') as prc
from (
	select SalesOrderID, OrderDate, TotalDue, SUM(TotalDue) over(order by salesorderid) as runn_tot, SUM(TotalDue) over() as Grand_total
	from [Sales].[SalesOrderHeader] 
	where DATEPART(YEAR, OrderDate)=@Year) x
order by SalesOrderID

exec Totaldue @Year=2012

--query that returns the list of 10 recommended products bought by another clients together with selected product, recommendations should not belong to the same subcategory as selected product
select top 5 * from [Sales].[SalesOrderDetail]
select top 5 * from [Production].[Product] 
select top 5 * from [Production].[ProductCategory]
select top 5 * from [Production].[ProductSubcategory]

--produstid, its subcategory, qty and total order amount for selected prodid:
-- 1) query that returns all orders and products bought with prodid = 776:
select SalesOrderID, STRING_AGG(ProductID, ', ')
from [Sales].[SalesOrderDetail] 
	where SalesOrderID in (select SalesOrderID
							from [Sales].[SalesOrderDetail] where productid=776)
		group by SalesOrderID


-- 2) converting to CTE and then to sp:
create procedure getOrdRec(@prodid int )
as
with RecProdCTE (ProdId, ProdSubId, subname, Qty, TotalVal)
as
(
	select sd2.ProductID, p.ProductSubcategoryID, s.name,
		SUM(sd2.OrderQty) as totalOrd,
		round(SUM(sd2.OrderQty*sd2.UnitPrice), 2) as total_price
	from [Sales].[SalesOrderDetail] sd1
	inner join [Sales].[SalesOrderDetail] sd2   --self join to extract in the where clause products bought together with selected productid but not including it in the output
		on sd1.SalesOrderID=sd2.SalesOrderID
	inner join [Production].[Product] p
		on sd2.ProductID=p.ProductID
	inner join [Production].[ProductSubcategory] s
		on p.ProductSubcategoryID=s.ProductSubcategoryID
	where sd1.ProductID=@prodid 
		and sd2.ProductID<>@prodid
	group by sd2.ProductID, p.ProductSubcategoryID, s.name
)
select top(10) ROW_NUMBER() over(order by rp.Qty desc) as rank,
	 rp.Qty, rp.prodid, rp.subname, rp.totalval, p.name
from RecProdCTE rp
	inner join [Production].[Product] p
		on p.ProductID=rp.prodid
where rp.prodsubid<>(select ProductSubcategoryID 
					from [Production].[Product] 
					where ProductID =@prodid)
order by rp.Qty desc

--drop procedure getOrdRec
exec getOrdRec 777

