--********************************************METADATA QUERIES:
select table_name
from information_schema.tables
where table_schema='dbo'

select *
--column_name, data_type, ordinal_position, is_nullable
from information_schema.columns
where table_name='emp'

-- query that lists indexes, their columns, and the column position (if available) in the index for a given table
alter table dept
--alter column deptno int not null
add constraint PK Primary key (deptno)

select top 5 *
from sys.indexes

select a.table_name,
		a.constraint_name,
		b.column_name,
		a.constraint_type
from information_schema.table_constraints a, information_schema.key_column_usage b
where a.table_name='dept'
		and a.table_name = b.table_name
		and a.table_schema = b.table_schema
		and a.constraint_name = b.constraint_name


-- using SQL query to write SQL query:

SELECT 'select count(*) from ' + TABLE_NAME +';'
from [SQLCookbook].INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'

-- or listing all column names:
select 'select ' + string_agg(column_name, ', ') + ' from ' + table_name
from information_schema.columns
where table_name='emp'
group by table_name



--************************************************************WORKING WITH STRINGS:

--query that lists each letter of selected cell in a separate row - using helper table t10:
select substring(e.ename, iter.n, 1)
from (select ename from emp  where ename='KING') e, 
	(select n from t10) iter
where iter.n<=len(e.ename)

-- or using ROW_NUMBER() window function on existing emp table:
select substring(e.ename, iter.n, 1)  -- substring(phrase, starting point, how many elements)
from (select ename from emp  where ename='KING') e, 
	(select ROW_NUMBER() over(order by deptno) n from emp) iter
where iter.n<=len(e.ename)

-- or using CTE:
with x (ename,s, n)
as
(
	select ename, substring(ename, 1, 1), 1
	from emp
	where ENAME='KING'
	union all
	select ename, substring(ename, n+1, 1), n+1
	from x
	where n<LEN(ename)

)

select s from x


-- counting the occurences of a character in a string: 
declare @x as varchar(100)='10,CLARK,MANAGER'
-- how many commas occur in x variable;
select (LEN(@x)-LEN(REPLACE(@x, ',', ''))) as 'no of commas'

-- important to divide by the length of counting string:
declare @y as varchar(100) = 'HELLO HELLO'
select (LEN(@y)- LEN(REPLACE(@y, 'LL', ''))) as 'incorrect',
		(LEN(@y)-LEN(REPLACE(@y, 'LL', '')))/LEN('LL') as 'correct'

-- query that removes all zeros from sal and vowels from ename:
select replace(translate(ename, 'AEIOU', '#####'),'#', ''), cast(replace(sal, 0, '') as int)
from emp

-- query that separates char and numeric data:
create view d
as
select ename + cast(sal as varchar(10)) as data
from emp 

select replace(TRANSLATE(data, '0123456789', REPLICATE('0', 10)), '0', '') as ename,
		cast(replace(data, replace(TRANSLATE(data, '0123456789', REPLICATE('0', 10)), '0', ''), '') as int ) as sal
from d

-- determining whether a string is alphanumeric, query that omits those rows containing data other than letters and digits:
create view V3 as  
 select ename as data  
 from emp  
  where deptno=10  
union all  
 select ename +', $'+ cast(sal as char(4)) +'.00' as data  
 from emp  
  where deptno=20  
union all  
 select ename+ cast(deptno as char(4)) as data  
 from emp  
  where deptno=30
   
select * from V3

select data 
from V3
where TRANSLATE(lower(data), '0123456789abcdefghijklmnopqrstuvwxyz', REPLICATE('#', 36))=REPLICATE('#', LEN(data))

-- extracting initials from a name:
select string_agg(left(value,1), '.') +'.' 
from string_split('Allen H.Ward', ' ')

-- query that orders records based on the last two characters of each name:
select ename,SUBSTRING(ename, LEN(ename)-1, 2)
from emp
order by SUBSTRING(ename, LEN(ename)-1, 2)

-- query that orders by a number in a string:
create view V4 as
select e.ename + ' ' + cast(e.empno as varchar(10)) + ' ' + d.dname as data
from emp e, dept d
	where e.deptno=d.deptno

select * from V4

select *
from V4
order by replace(TRANSLATE(data, 'abcdefghijklmnopqrstuvwxyz', replicate('#', 26)), '#', '')

-- query that returns one row per each deptno with a list of employees:
select deptno, string_agg(ename, ', ')
from emp
group by deptno


-- alphabetizing a string:

select ename,
	max(case when pos=1 then c else '' end)+
	max(case when pos=2 then c else '' end)+
	max(case when pos=3 then c else '' end)+
	max(case when pos=4 then c else '' end)+
	max(case when pos=5 then c else '' end)+
	max(case when pos=6 then c else '' end)
from (
select e.ename,
			substring(e.ename,iter.pos,1) as c,
			row_number() over (partition by e.ename order by substring(e.ename,iter.pos,1)) as pos from emp e,
			(select row_number()over(order by ename) as pos from emp) iter  -- column with only row numbers
where iter.pos <= len(e.ename)) x
group by ename

--extracting only numeric data:
create view V5 as
	select replace(mixed,' ','') as mixed
		from (select substring(ename,1,2) +  cast(deptno as char(4)) +  substring(ename,3,2) as mixed
				from emp
				where deptno = 10
union all
	select cast(empno as char(4)) as mixed
		from emp
		where deptno = 20
union all
	select ename as mixed
		from emp
		where deptno = 30
) x
select * from v5

select replace(TRANSLATE(mixed, 'abcdefghijklmnopqrstuvwxyz', replicate('#', 26)), '#', '') only_num
from v5
where isnumeric(replace(TRANSLATE(mixed, 'abcdefghijklmnopqrstuvwxyz', replicate('#', 26)), '#', ''))>0

-- query that extracts the nth delimited substring:
create view v6 as
select deptno, STRING_AGG(ename, ', ') agg_name
from emp
group by deptno

select * from v6
--extracting 2nd item:

select value from string_split((select STRING_AGG(agg_name, ', ') from v6), ',')
order by value offset 1 row fetch first 1 rows only

-- or stored procedure with variable as row number:

create procedure numrow @n int
as
select value
from string_split(
(select STRING_AGG(agg_name, ', ') from v6), ',')
order by value
offset @n-1 rows
fetch next 1 rows only

exec numrow 5;

select * from v5
where mixed like '%[0-9]%'


-- **************************************************************WORKING WITH NUMBERS:
-- AVERAGE does not take into consideration NULL values (only if NULL are replaced with 0 e.g. using coalesce))
select deptno, count(*), count(comm), count('hello')
from emp
group by deptno

-- running total:
select ename, sal, 
	sum(sal) over(order by sal, empno)  -- including PK in the order by clause allows to avoid duplicates (sal and empno create unique combination)
from emp

-- calculating the mode (the element that appears most frequently)

select sal
from(
	select sal, 
			DENSE_RANK() over (order by cnt desc) as rnk -- order desc the highest cnt value will be the first element
	from (select sal, COUNT(*) as cnt -- salary 3000 occurs the most frequently
		from emp
		where deptno=20
		group by sal) x ) y
where rnk =1


-- calculating a median (a value of the middle member of a set of ordered elements)
select distinct(PERCENTILE_CONT(0.5) within group(order by sal) over()) as median
from emp
where deptno =20

-- determining the percentage of a total - what percentage of all salaries are the salaries in deptno 10:

select distinct(cast(100*(cast(dep_sum as float)/cast(total as float)) as numeric(5,2))) as '%'
from (select deptno, SUM(sal) over(partition by deptno) dep_sum, SUM(sal) over() as total
from emp) x
where deptno =10

-- computing averages without high and low values (reducing the effect of skew = trimmed mean):
select avg(sal)
from (
	select sal, min(sal) over() as min_sal,
			MAX(sal) over() as max_sal
	from emp) x
where sal not in (min_sal, max_sal)

-- converting alphanumeric string into number:
declare @x as varchar(40)= 'paul123f321'

select cast(replace(TRANSLATE(@x, 'abcdefghijklmnopqrstuvwxyz', REPLICATE('#', 26)),'#', '') as int) as number

-- changing values in a running total:
create view V7 (id,amt,trx)
as
select 1, 100, 'PR' union all
select 2, 100, 'PR'  union all
select 3, 50, 'PY' union all
select 4, 100, 'PR' union all
select 5, 200, 'PY' union all
select 6, 50, 'PY' 

select * from v7
-- PR = purchase, PY = payment , if status is purchase -> its value should be added to the running total, else if status is payment - > should be subtracted
select id,
		case
			when trx='PR' then 'Purchase'
			when trx='PY' then 'Payment'
		end as status,
	   amt,
	   SUM(r) over(order by id) as run_total
from (select id, trx, amt, case
			when trx='PR' then amt
			when trx='PY' then -amt
		end as r
	from v7) x

-- finding outliers using the median absolute deviation:
-- 1) deviation = absolute difference between each value and median
-- 2) median absolute deviation = median from deviation computed in point 1st



with median(median) 
as
		(select distinct PERCENTILE_CONT(0.5) within group(order by sal) over()
		from emp),

	Deviation (Deviation)
	as
		(Select abs(sal-median)
		from emp join median on 1=1),

	MAD (MAD)
	as
		(select DISTINCT PERCENTILE_CONT(0.5) within group(order by deviation) over()
		from Deviation )


select abs(sal-MAD)/MAD, sal, ename, job
from MAD join emp on 1=1



--*************************************************************DATE ARITHMETIC:
--dateadd function to add/substract different units of time:

select hiredate as HD,
	DATEADD(DAY, -5, hiredate) as hd_minus_5D,
	dateadd(day,5,hiredate) as hd_plus_5D,
	dateadd(month,-5,hiredate) as hd_minus_5M,
	dateadd(month,5,hiredate) as hd_plus_5M,
	dateadd(year,-5,hiredate) as hd_minus_5Y,
	dateadd(year,5,hiredate) as hd_plus_5Y
from emp
where deptno = 10

-- the difference in days between the HIREDATEs of employee ALLEN and employee WARD.
select DATEDIFF(day, (select hiredate from emp where ename='ALLEN'),(select hiredate from emp where ename='WARD')) as day_diff

--or:
select DATEDIFF(day, HD_Allen, HD_Ward) as date_diff
from(
	select hiredate as HD_Allen
	from emp 
	where ename='ALLEN') x,
	(select hiredate as HD_Ward
	from emp 
	where ename='WARD') y


-- the difference in working days:
declare @DateFrom as datetime = '20220404' --(select hiredate from emp where ename='ALLEN');
declare @DateTo as datetime = '20220420' --(select hiredate from emp where ename='WARD');
 
declare @TotalWorkDays as int = DATEDIFF(DAY, @DateFrom, @DateTo)
				    -(DATEDIFF(WEEK, @DateFrom, @DateTo) * 2)  -- week => datediff considers week as a combination of Saturday and Sunday =1, so to get the number of weekend days the result must be mutiplied by 2
					   -CASE  -- checking if start/end days are weekends, if yes must be subtracted
                                    WHEN DATENAME(WEEKDAY, @DateFrom) = 'Sunday'
                                    THEN 1
                                    ELSE 0
                                END+CASE
                                        WHEN DATENAME(WEEKDAY, @DateTo) = 'Saturday'
                                        THEN 1
                                        ELSE 0
                                    END;

select @TotalWorkDays

-- FUNCTION THAT ADDS WORKING DAYS:
CREATE FUNCTION ADDWD(@addDate AS DATE, @numDays AS INT)
RETURNS DATETIME
AS
BEGIN
    WHILE @numDays>0
    BEGIN
       SET @addDate=DATEADD(d,1,@addDate)
       IF DATENAME(DW,@addDate)='saturday' SET @addDate=DATEADD(d,1,@addDate)
       IF DATENAME(DW,@addDate)='sunday' SET @addDate=DATEADD(d,1,@addDate)

       SET @numDays=@numDays-1
    END

    RETURN CAST(@addDate AS DATETIME)
END
GO

select dbo.ADDWD(getdate(), 8)

-- the difference in hours, minutes, seconds between the HIREDATEs of employee ALLEN and employee WARD.
select DATEDIFF( hour, HD_Allen, HD_Ward) as hours,
	DATEDIFF(minute, HD_Allen, HD_Ward) as minutes,
	DATEDIFF(second, HD_Allen, HD_Ward) as seconds
from
	(select hiredate as HD_Allen
	from emp 
	where ename='ALLEN') x,
	(select hiredate as HD_Ward
	from emp 
	where ename='WARD') y

-- declaring the first and the last day of the current year:
select start as start_date, dateadd(day, -1, DATEADD(YEAR, 1, start)) as end_date
from (select cast(cast(year(getdate()) as varchar)+'-01-01' as date) as start) x


-- query that counts the number of weekdays in the year
-- creating recursive CTE to populate the whole year with days starting from the 1st of January:

with x (start_date, end_date)
as
-- anchor member:
(select start as start_date, dateadd(day, -1, DATEADD(YEAR, 1, start)) as end_date
from (select cast(cast(year(getdate()) as varchar)+'-01-01' as date) as start) anc

union all
--recursive part => adding one day starting from start_date:
select DATEADD(DAY, 1, start_date), end_date
from x
where DATEADD(DAY, 1, start_date)<=end_date
)

select DATENAME(DW, start_date), COUNT(*)
from x
group by DATENAME(DW, start_date)
option(maxrecursion 400)  -- default recursion = 100 

-- determining the date difference between the current record and the next record (next after duplicated records):
-- for each records from 17.11 the next record is 27.11
select ename, hiredate 
from emp2
where deptno=10
order by hiredate

select deptno, ename, hiredate, hd, datediff(day,hiredate, hd) as diff
from (
	select deptno, ename, hiredate,
		lead(hiredate, cnt-rn+1) over(order by hiredate) as hd  --contains value from next row, second argument determines the size of step
	from (select deptno, ename,hiredate,
		COUNT(*) over(PARTITION by hiredate) as cnt,
		row_number() over (PARTITION by hiredate order by empno) as rn
		from emp2
		where deptno=10
		) x 
		) y



--******************************************************DATE MANIPULATION:
--determining whether the current year is a leap year:

select case when try_cast(concat(year(getdate()),'-02-29')as date) is null 
		then 'non leap year' 
		else 'leap year' 
	end as leap_year;


--determining the number of days in a year:
select DATEDIFF(DAY, start_date, end_date)+1 as no_days -- add 1 as the
from (
select start_date, dateadd(day, -1,DATEADD(YEAR, 1, start_date)) as end_date
from (
		select cast(cast(YEAR(GETDATE()) as varchar) + '-01-01' as date) as start_date
) x 
) y

select dateadd(d,-datepart(dy,getdate())+1,getdate()) curr_year
select datepart(dy,getdate())

select datediff(d,curr_year,dateadd(yy,1,curr_year))
from (
select dateadd(d,-datepart(dy,getdate())+1,getdate()) curr_year  --= 1st of January, datepart -> dy = the number of days from the beginning of year
) x

-- extracting time parts from current date:
select datepart( hour, getdate()) hr,
	datepart( minute,getdate()) min,
	datepart( second,getdate()) sec,
	datepart( day, getdate()) dy,
	datepart( month, getdate()) mon,
	datepart( year, getdate()) yr


-- determining the first and last days of a month
select start_date, dateadd(MONTH, 1, start_date)-1 as end_date
from (select dateadd(day,-datepart(D, getdate())+1,getdate()) as start_date --instead of datepart might be day(getdate())
)x

select DAY(GETDATE())

-- determining all dates for a particular weekday throught a year starting from today:
with x (start_date)
as
(
	select start_date
	from (select dateadd(day, -DAY(GETDATE())+1, GETDATE()) as start_date) anc
	union all
	select DATEADD(DAY, 1, start_date)
	from x
	where start_date<=CAST(cast(YEAR(GETDATE()) as varchar)+'-12-31' as date)
)

select start_date
from x
where datename(dw, start_date) = 'Friday'
option(maxrecursion 400) 

-- or the number of particular weekday till the end of the year:
select datename(dw, start_date), COUNT(*) as no_count
from x
group by datename(dw, start_date)
having datename(dw, start_date) = 'Friday'
option(maxrecursion 400) 

-- determining the date of the first and last occurences of a specific weekday in a month:
with x (start_date)
as 
(
	select start_date--, dateadd(MONTH, 1, start_date)-1 as end_date
	from (select DATEADD(DAY, -DAY(getdate())+1, GETDATE()) as start_date) anc
	union all
	select DATEADD(DAY, 1, start_date)
	from x
	where start_date<dateadd(MONTH, 1, DATEADD(DAY, -DAY(getdate())+1, GETDATE()))  --start_date cannot be used in where clause => infinite loop

)
select min(start_date) as 'first', MAX(start_date) as 'last'
from x
where DATENAME(dw, start_date) = 'Friday'
option(maxrecursion 400) 




-- CREATING A CALENDAR:
with x(start_date,dm,mth,dw,wk)
as (
select start_date,		-- 01.04.2022
	day(start_date) dm,		-- 1 -> only day from the start_date
	datepart(m,start_date) mth,		-- 4 -> month
	datepart(dw,start_date) dw,		-- 6 -> dw = weekday; which day of the week (it was Friday, starting from Sunday)
		case when datepart(dw,start_date) = 1	-- if weekday = Sunday move to the previous week
			then datepart(ww,start_date)-1		-- 14 -1 the number of week from the beggining of year
		else datepart(ww,start_date)
		end wk
from (select DATEADD(DAY, -DAY(getdate())+1, GETDATE()) as start_date) x -- the first day of the month
union all
select dateadd(d,1,start_date), day(dateadd(d,1,start_date)), mth,  -- selecting the same parameters as in the above anchor statement but incrementing start_date by 1 day
		datepart(dw,dateadd(d,1,start_date)),
		case when datepart(dw,dateadd(d,1,start_date)) = 1
			then datepart(wk,dateadd(d,1,start_date)) -1
		else datepart(wk,dateadd(d,1,start_date))
		end
from x
where datepart(m,dateadd(d,1,start_date)) = mth)

select max(case dw when 2 then dm end) as Mo,  -- each group of week will have only one value for particular weekday, selecting max allows to exclude nulls
		max(case dw when 3 then dm end) as Tu,
		max(case dw when 4 then dm end) as We,
		max(case dw when 5 then dm end) as Th,
		max(case dw when 6 then dm end) as Fr,
		max(case dw when 7 then dm end) as Sa,
		max(case dw when 1 then dm end) as Su
--select dw, dm, wk
from x
group by wk--group by each week
order by wk

select datepart(ww,start_date)
from (select DATEADD(DAY, -DAY(getdate())+1, GETDATE()) as start_date) x

select datepart(ww,'2022-01-31')

-- listing quarters start and end dates for the year:
with x (start_date)
as
(
	select start_date
	from (select DATEADD(DAY, -DAtepart(dy, getdate())+1, getdate()) as start_date) y
	union all
	select DATEADD(DAY, 1, start_date)
	from x
	where start_date < DATEADD(year, 1, DATEADD(DAY, -DAtepart(dy, getdate())+1, getdate()))-1
)
select min(start_date) first_q, Max(start_date) last_q
from x
group by DATEPART(QUARTER, start_date)
option(maxrecursion 400)

--counting the number of hires in each month - even if no employee was hired:
--below query does not include zeroes:
select data, COUNT(*) hired_emp
from (select convert(varchar(7), hiredate, 126) as data
from emp) x
group by data

-- including all months:
with x (start_date, end_date)
as
(
	select start_date, end_date
	from (select min(hiredate)- DATEPART(DY, MIN(hiredate))+1 as start_date,
		DATEadd(year, 1, max(hiredate)- DATEPART(DY, Max(hiredate))) as end_date
	from emp) y
	union all
	select dateadd(day, 1, start_date), end_date
	from x 
	where start_date<end_date
)
select convert(varchar(7), start_date, 126), convert(varchar(7), emp.hiredate, 126),  COUNT(emp.hiredate),
sum(COUNT(emp.hiredate)) over()
from x
left join emp
	on x.start_date=emp.hiredate
group by convert(varchar(7), start_date, 126), convert(varchar(7), emp.hiredate, 126)
order by 1
option(maxrecursion 4000)


-- and extracting only months and years when the highest number of employees were hired:
with x (startdate, maxdate)
as
(
	select MIN(hiredate) as startdate, MAX(HIREDATE) as maxdate
	from emp
	union all
	select DATEADD(DAY, 1, startdate), maxdate
	from x
	where DATEADD(DAY, 1, startdate)<= maxdate
)
select month, emp_hired
from(
	select *, DENSE_RANK() over(order by emp_hired desc) r   -- dense rank descending -> first element returns the biggest number 
	from(
		select convert(varchar(7), x.startdate, 126) as month, count(empno) as emp_hired
		from x
		left join emp e
			on x.startdate=e.HIREDATE
		group by convert(varchar(7), x.startdate, 126)
		)y
	)z
where r=1
option (maxrecursion 32000) 



-- searching on specific units of time - select the employees who were hired in February, December or Sunday:
select ename, DATENAME(m, hiredate) as month, DATENAME(Dw, hiredate) as weekday
from emp
where DATENAME(m, hiredate) in ('February', 'December')
	or DATENAME(Dw, hiredate) = 'Sunday'

--query that finds which employees have been hired on the same month and weekday:
select convert(varchar(7), e.hiredate, 126), string_agg(e.ename, ', ')--, m.hiredate
from emp e
	join emp m
	on e.empno=m.empno
where convert(varchar(7), e.hiredate, 126) = convert(varchar(7), m.hiredate, 126) and e.empno<m.empno
group by convert(varchar(7), e.hiredate, 126)--, e.ename

select e.ename + ' has been hired in the same month: '+ cast(month(e.hiredate) as varchar) + ' and weekday '+ DATEname(DW, e.hiredate) +' as '+m.ename
,e.ename, month(e.hiredate) as month, DATEname(DW, e.hiredate) as weekday, convert(varchar(7), e.hiredate, 126), m.ename
from emp e--, emp m
	join emp m
	--on convert(varchar(7), e.hiredate, 126) = convert(varchar(7), m.hiredate, 126)
		on month(e.hiredate) = month(m.hiredate) 
			and DATEPART(DW, e.hiredate) = DATEPART(DW, m.hiredate)
			and e.empno<m.empno
-- or: where e.empno<m.empno



--***********************************************WORKING WITH RANGES:
-- query that determines which rows represent a range of consecutive projects (end date of one project should be start date for another):

-- using self join:
select cast(r1.proj_id as varchar)+ ' ends and proj ' + cast(r2.proj_id as varchar) + ' starts', r1.proj_s, r1.proj_e
from range r1, range r2
	where r1.proj_e=r2.proj_s --and r1.proj_id<r2.proj_id
	and r1.proj_id!=r2.proj_id

-- or window function:
select proj_id, proj_s, proj_e
from (select proj_id, LEAD(proj_s) over (order by proj_id) as lead, proj_s, proj_e
	from range) x
where proj_e = lead

-- query that returns the DEPTNO, ENAME, and SAL of each employee along with the difference in SAL between employees in the same department
-- all employees hired on the same date (November 17) should evaluate their salary against another employee hired on next day in the future (not 17.11)

-- incorrect - when hiredate is the same for several employees
select deptno, ename, sal,  hiredate, SAL-lead as diff 
from (select deptno, ename, sal,  hiredate, Lead(SAL) over(partition by deptno order by hiredate) as lead
	from emp) x
order by deptno

-- correct solution - computing difference between the total number of rows with the same hiredate within each deptno and row number within each deptno -> using this result as a second argument in the lead function (how many rows skip)
select deptno, ename, sal,  hiredate, SAL-lead as diff 
from (select deptno, ename, sal,  hiredate, 
		LEAD(sal, cnt-r+1) over (PARTITION by deptno order by hiredate) as lead,
		r
	from 
	( select deptno, ename, sal,  hiredate, 
		COUNT(*) over(partition by deptno, hiredate) as cnt, 
		Row_number() over (PARTITION by deptno, hiredate order by hiredate) as r
	 from emp3) x
	) y
order by deptno

-- query that returns the groups of consecutive values:

select proj_id, proj_s, proj_e, r, sum(r)over(order by proj_id) proj_grp
from(select proj_id, proj_s, proj_e, 
	case
		when proj_s=lag(proj_e) over (order by proj_id) then 0 else 1  -- important to return 0 when result is true
	end AS r															-- for the first element in the group returns 1, for the rest of elements in the group 0, hence the running sum for the whole group is increased by 1
from range) x

--finally:
select MIN(proj_s), MAX(proj_e)
from (select proj_id, proj_s, proj_e, r, sum(r)over(order by proj_id) proj_grp
	from(select proj_id, proj_s, proj_e, 
	case
		when proj_s=lag(proj_e) over (order by proj_id) then 0 else 1  -- important to return 0 when result is true
	end AS r
from range) x
) y
group by proj_grp


--query that returns the number of employees hired each year for the entire decade of the 2005s, but there are some years in which no employees were hired (including zeroes)
select YEAR(hiredate), COUNT(*)
from emp
group by YEAR(hiredate)

-- 1st way with recursive CTE:
with x (fy, ly)
as
(
	select fy, ly
	from (select MIN(hiredate) as fy, DATEADD(YEAR, 10, MIN(hiredate)) ly
			from emp
			) y
	union all
	select DATEADD(YEAR, 1, fy), ly
	from x
	where DATEADD(YEAR, 1, fy)<= ly
)

select YEAR(fy), year(emp.HIREDATE), COUNT(emp.HIREDATE)
from x
	left join emp
	on year(x.fy)=year(emp.HIREDATE)
group by YEAR(fy), year(emp.HIREDATE)
order by YEAR(fy)

--2nd way:
	-- shorter query that returns 10 consecutive years:
	select top (10)
			 year(min(hiredate)over())+(row_number()over(order by hiredate)-1) yr
	from emp

select yr, COUNT(e.HIREDATE) as no_emp
from (select top (10)
			 year(min(hiredate)over())+(row_number()over(order by hiredate)-1) yr
	from emp) x
left join emp e
	on x.yr=year(e.HIREDATE)
group by x.yr, year(e.HIREDATE)
order by x.yr

-- generating consecutive numeric values:
with x (id)
as
(
	select 1
	union all
	select id+1
	from x
	where id<10
)
select * from x

