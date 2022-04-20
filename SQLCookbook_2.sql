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
