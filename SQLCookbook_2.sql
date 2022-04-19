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
