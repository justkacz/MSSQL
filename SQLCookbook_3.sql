-- ******************************************************ADVANCED SEARCHING:
-- Window functions are applied after the WHERE clause. To filter results after window functions have been evaluated, the windowing
-- query must be put into an inline view and then filter on the results from that view

--paginating through a result set:
-- using window function row_number:
select sal 
from (select sal, 
	ROW_NUMBER() over(order by sal) as r
	from emp) x
where r between 1 and 5       --including 1 and 5

-- or manipulating offset and fetch values:
select sal
from emp
order by sal
offset 5 rows
fetch next 5 rows only

-- skipping n rows from a table, query that returns every other row:
select ename
from (select ename,
	ROW_NUMBER()over (order by ename) as r
	from emp) x
where r % 2 =1

--query that returns the name and department information for all employees in departments 10 and 20 along with department information for departments 30 and 40 (but no employee information):
-- 39%
select e.ename, d.deptno, d.dname, d.loc
from dept d
	left join emp e
		on e.deptno=d.deptno and (e.deptno =10 or e.deptno = 20)   -- emp table is filtered and to the whole dept table are joined only records from 10 or 20 department
order by d.deptno

-- 39% or:
select e.ename, d.deptno, d.dname, d.loc
from dept d							-- to the whole dept tablt with all departments is attached emp table only with deptno 10 or 20
	left join
		(select ename, deptno
		from emp
		where deptno in ( 10, 20 )
		) e on ( e.deptno = d.deptno )
order by 2

-- 22% or with union all => THE MOST OPTIMIZED:
select e.ename, e.deptno, d.dname, d.loc
from emp e
	left join dept d
	on e.DEPTNO=d.DEPTNO
where e.DEPTNO in (10,20)
union all
select null, deptno, dname, loc
from dept 
where DEPTNO in (30,40)



-- selecting the top n records:
--50% using window function rank/dense_rank() -> counts the same sal value for multiple emp as a one record:
select ename, sal, r
from (select ename, sal,
	RANK() over(order by sal) as r
	from emp) x
where r<=10

-- 50% or with top ties: the same result as using rank(), more records returned when using dense_rank()
select top 10 with ties ename, sal
from emp
order by sal


-- looking for the extreme values, employees with the highest and lowest salaries:
select ename
from (select ename, sal,
	min(sal) over() as minv,
	MAX(sal) over() as maxv
	from emp
) x
where sal in (minv, maxv)

-- query that finds any employees who earn less than the employee hired immediately after them:
--assuming that only one employee has been hired each day:
select ename, sal, hiredate, l 
from (select ename, sal, hiredate,
	LEAD(sal) over (order by hiredate) as l
	from emp) x
where sal<l
order by hiredate

-- or that more than one employee might be hired one day:
select ename, sal, hiredate, l 
from (select ename, sal, hiredate,
	LEAD(sal, cnt-r+1) over (order by hiredate) as l
	from (select ename, sal, hiredate,
			COUNT(*) over (PARTITION by hiredate) as cnt,
			ROW_NUMBER() over (PARTITION by hiredate order by empno) as r 
			from emp) x
			) y
where sal<l
order by hiredate

-- shifting row values, query that returns each employee’s name and salary along with the next highest and lowest salaries:
select ename, sal,
	case 
	when r = MAX(r) over() then min(sal) over()  else forward
	end as forward,
	case 
	when r = 1 then max(sal) over() else reward
	end as reward
from (select ename, sal,
			LEAD(sal) over(order by sal) as forward,
			LAG(sal) over (order by sal) as reward,
			ROW_NUMBER() over (order by sal) as r
			from emp
			--order by sal
	) x

--or shorter with using coalesce:
select ename, sal, 
	coalesce(LEAD(sal) over(order by sal), min(sal) over()) as forward,
	coalesce(Lag(sal) over(order by sal), max(sal) over()) as reward
from emp

-- ranking results with ties:
select sal, 
	dense_rank() over (order by sal)
from emp

-- 50% selecting distinct values in the column:
select distinct job
from emp

-- 50%  or by using window function:
select job, r
from (select job, ROW_NUMBER() over(PARTITION by job order by sal) as r
	from emp
) x
where r=1

-- 50% query that returns the employee's details and the salary of the last employee hired, in each department:

select deptno, ename, sal, hiredate,
	max(lead) over(partition by deptno) as last_salary
from (select deptno, ename, sal, hiredate,
	LEAD(sal, cnt-1) over(partition by deptno order by hiredate) as lead
	from (select deptno, ename, sal, hiredate,
			count(*) over (partition by deptno) as cnt
			from emp
	) x
	) y

-- 50% or with using CASE:
select deptno, ename, sal, hiredate,
	MAX(last) over(partition by deptno) as last_sal
from (select deptno, ename, sal, hiredate,
	case 
		when hiredate=max(hiredate) over (PARTITION by deptno) then sal else 0
	end as last
	from emp
) x

--*********************************************************REPORTING AND RESHAPING:
--pivoting into one row:
select deptno, COUNT(*) cnt
from emp
group by deptno

select deptno,			-- the whole table has 14 rows:
	sum(case when deptno=10 then 1 else 0 end) as dept10, -- each row is verified which deptno belongs to (1 otherwise 0)
	sum(case when deptno=20 then 1 else 0 end) as dept20, 
	sum(case when deptno=30 then 1 else 0 end) as dept30
from emp
group by deptno
order by deptno

select 		
	sum(case when deptno=10 then 1 else 0 end) as dept10,	--the sum results with the total number of rows in each department
	sum(case when deptno=20 then 1 else 0 end) as dept20, 
	sum(case when deptno=30 then 1 else 0 end) as dept30
from emp

-- or with using inline view:
select max(case when deptno=10 then cnt end) as dept_10,
	max(case when deptno=20 then cnt end) as dept_20,
	max(case when deptno=30 then cnt end) as dept_30
from (select deptno, COUNT(*) cnt
	from emp
	group by deptno
	) x

-- pivoting into multiple rows (job as a column header, enames as the values):
select job, ename
from emp
order by 1

-- below query will return only one ename for each job:
select
	max(case when job='analyst' then ename end) as Analyst,
	max(case when job='clerk' then ename end) as Clerk,
	max(case when job='manager' then ename end) as Manager,
	max(case when job='president' then ename end) as President,
	max(case when job='salesman' then ename end) as Salesman
from emp

-- by adding row_number for each job we will receive the unique pairs, combinations of ename and row number for each job:
select
	max(case when job='analyst' then ename else null end) as Analyst,
	max(case when job='clerk' then ename end) as Clerk,
	max(case when job='manager' then ename end) as Manager,
	max(case when job='president' then ename end) as President,
	max(case when job='salesman' then ename end) as Salesman
from (
	select job, ename,
		ROW_NUMBER() over(PARTITION by job order by ename) as r
	from emp
) x
group by r  -- could not be used in the inner query as windowed functions can only appear in the SELECT or ORDER BY clauses


-- reverse pivoting:
select * from pivot_dept

-- creating Cartesian product - joining with table which has at least 3 rows (dept table):
select d.deptno,
	case
		when deptno=10 then pd.dept_10
		when deptno=20 then pd.dept_20
		when deptno=30 then pd.dept_30
	end as dept
from dept d, pivot_dept pd
	where d.deptno<=30
group by d.deptno

-- pivoting result set into one column:
-- query that returns all columns from a query (ename, job and salary) as just one column:

with x (id)
as
(			-- declaring 1st CTE with 4 rows:
	select 1
	union all
	select id+1
	from x
	where id+1<=4
)		
			-- declaring 2nd CTE - filling 4 rows with values from emp table:
, fill_emp (ename, job, sal,r)
as 
(
	select ename, job, sal, 
	ROW_NUMBER() over(PARTITION by empno order by empno)
	from emp e1
	join x e2
		on 1=1   -- always true, in this example the same behaviour as cross join -> 'from emp e1 cross join x e2'; 
				 -- e.g. joining table a with empty table b -> 1=1 will return only a table, cross join will return empty table
)
select case
	when r=1 then cast(ename AS varchar)
	when r=2 then cast(job AS varchar)
	when r=3 then cast(sal AS varchar)
	end as emp_list
from fill_emp

--suppressing repeating values (e.g. when uing group by):
select case when r=1 then deptno else null end as deptno,
		ename
from (select deptno, ename,
	ROW_NUMBER() over(partition by deptno order by empno) r
	from emp) x

-- or shorter solution using LAG() OVER()
select  
	case when Lag(deptno) over(partition by deptno order by empno) is null then deptno else null end as dep,
	ename
from emp

--or:
select deptno, Lag(deptno) over(order by deptno), ename,
	case when
		lag(deptno)over(order by deptno) = deptno then null else deptno end DEPTNO
from emp

-- pivoting and performing inner row calculation:
-- calculating the difference in the total salary amount in each department, the result should be as an inline view:
select deptno, SUM(sal)  --the highest combined salary is in the dept 20
from emp
group by deptno 


select 
	max(case when deptno=10 then tot-lead end) as diff_10_20,
	max(case when deptno=20 then tot-lead end) as diff_20_30
	from (
		select deptno, tot,
			LEAD(tot) over(order by deptno) lead
				from (select deptno, SUM(sal) tot
						from emp
						group by deptno) x		  
) y		

-- or:
select d10_sal-d20_sal as d10_20_diff,
	d20_sal-d30_sal as d20_30_diff
from(   -- inner query that transposes total sal in each deptno to inline view:
	select sum(case when deptno=10 then sal end) as d10_sal,
		sum(case when deptno=20 then sal end) as d20_sal,
		sum(case when deptno=30 then sal end) as d30_sal
	from emp) x

-- or with using CTE:
with x (d10_sal, d20_sal, d30_sal)
as
(
	select sum(case when deptno=10 then sal end) as d10_sal,
		sum(case when deptno=20 then sal end) as d20_sal,
		sum(case when deptno=30 then sal end) as d30_sal
	from emp
)
select d10_sal-d20_sal as d10_20_diff,
	d20_sal-d30_sal as d20_30_diff
	from x

-- creating fixed size buckets of data, the number of buckets is not defined:
-- the number of buckets might be unknown but each group should contain 5 rows - function ceiling combined with row_number divided by 5:

select ROW_NUMBER() over (order by empno) row_num,
cast(ROW_NUMBER() over (order by empno) as numeric(5,2))/5 as div,
ceiling(cast(ROW_NUMBER() over (order by empno)as numeric(5,2))/5)r,
empno, ename
from emp

-- creating defined number of buckets:
-- NTILE window function - organizes an ordered set into the number of buckets specified as an argument
select NTILE(4) over (order by empno) as buckets, 
empno, ename
from emp

-- CREATING HISTOGRAM (each * as one employee):
-- a) vertical:
select deptno, replicate('*', COUNT(*)) as hist
from emp
group by deptno

-- b) horizontal:
--inner query that displays 1 where emp belongs to the particular department
select deptno,
	case when deptno=10 then 1 else 0 end as d10, 
	case when deptno=20 then 1 else 0 end as d20,
	case when deptno=30 then 1 else 0 end as d30
from emp

-- finally
select MAX(deptno_10) d10, 
	MAX(deptno_20) d20,
	MAX(deptno_30) d30
from (
select row_number()over(partition by deptno order by empno) rn
	,case when deptno=10 then '*' else null end deptno_10,
	case when deptno=20 then '*' else null end deptno_20,
	case when deptno=30 then '*' else null end deptno_30
from emp)x
group by rn
order by d10, d20, d30 desc

-- returning non group by columns:
--query that finds the employees who earn the highest and lowest salaries in each department, as well as the 
-- employees who earn the highest and lowest salaries in each job

select deptno, ename, job, sal
from emp

-- inner query to find the highest and lowest salaries by job and department:
select deptno,ename,job,sal,
	case 
		when sal=maxd then 'TOP SAL IN DEPT' 
		when sal=mind then 'LOW SAL IN DEPT' 
	end as DEPT_STATUS,
	case 
		when sal=maxj then 'TOP SAL IN	JOB'
		when sal=minJ then 'LOW SAL IN JOB' 
	end as JOB_STATUS
from
	(select deptno,ename,job,sal,
		MAX(sal) over (partition by deptno) maxd,
		MAX(sal) over (partition by job) maxj,
		Min(sal) over (partition by deptno) mind,
		Min(sal) over (partition by job) minj
	from emp) x
order by deptno, job

-- CALCULATING SUBTOTALS:
-- using union all:
select job, SUM(sal) as sal
from emp
group by job
union all
select 'TOTAL', SUM(sal)
from emp

-- or ROLLUP:
select coalesce(job, 'TOTAL') as job, SUM(sal) as sal
from emp
group by job with rollup 

-- query that finds the sum of all salaries by DEPTNO, and by JOB, for every JOB/ DEPTNO combination:
select coalesce(cast(deptno as varchar), 'TOTAL FOR JOB'), coalesce(job, 'TOTAL FOR DEPT'), sum(sal)
from emp
group by cube(deptno, job)
order by deptno desc, job desc 

-- adding grouping in the select statement allows to identify which rows were grouped (marked as 0)
select deptno, job, --cast(grouping(deptno) as varchar), GROUPING(job),
	case
		when cast(grouping(deptno) as varchar)+cast(GROUPING(job) AS varchar)='00' then 'TOTAL BY DEPT AND JOB'
		when cast(grouping(deptno) as varchar)+cast(GROUPING(job) AS varchar)='11' then 'GRAND TOTAL FOR THE WHOLE TABLE'
		when cast(grouping(deptno) as varchar)+cast(GROUPING(job) AS varchar)='01' then 'TOTAL BY DEPT '+ CAST(deptno AS varchar)
		when cast(grouping(deptno) as varchar)+cast(GROUPING(job) AS varchar)='10' then 'TOTAL BY JOB ' + job
	end as 'Total dept, job and all',
	SUM(sal) as sal
from emp
group by cube(deptno, job)
order by deptno desc, job desc 

--GROUPING -> used with CUBE and ROLLUP -> allows to differentiate rows grouped by normal cube/rollup:
-- 0 means that column is included in the group clause:
select deptno, job, cast(grouping(deptno) as varchar), GROUPING(job), SUM(sal)
from emp
group by cube(deptno, job)
order by deptno desc, job desc

select ename, 
		case when job='CLERK' then 1 else 0 end as 'IS_CLERK',
		case when job='SALESMAN' then 1 else 0 end as 'IS_SALESMAN',
		case when job='MANAGER' then 1 else 0 end as 'IS_MANAGER',
		case when job='ANALYST' then 1 else 0 end as 'IS_ANALYST',
		case when job='PRESIDENT' then 1 else 0 end as 'IS_PRESIDENT'
from emp

-- SPARK MATRIX:
select --ename, 
		case when job='CLERK' then ename else '' end as 'IS_CLERK',
		case when job='SALESMAN' then ename else '' end as 'IS_SALESMAN',
		case when job='MANAGER' then ename else '' end as 'IS_MANAGER',
		case when job='ANALYST' then ename else '' end as 'IS_ANALYST',
		case when job='PRESIDENT' then ename else '' end as 'IS_PRESIDENT'
from emp

-- aggregations over diferent groups/partitions simultaneously:
-- query that for each employee returns the number of employees from the same department and job (two separate columns):

select ename, deptno, COUNT(*) over(partition by deptno) as deptno_cnt,
	job,
	COUNT(*) over(partition by job) as job_cnt, 
	COUNT(*) over(partition by deptno)+COUNT(*) over(partition by job) as total__dep_job,
	count(*) over () as grand_total, 
from emp

-- aggregations over moving range of values, computing a sum for every 90 days -> subquery in the select statement:

select hiredate, sal
from emp

select hiredate, sal, (select SUM(sal) from emp d
						where d.hiredate between e.hiredate-90 and e.hiredate) runn_sum
from emp e
order by hiredate

select e.hiredate,
e.sal,
(select sum(sal) from emp d
where d.hiredate between e.hiredate-90
and e.hiredate) as spending_pattern
from emp e
order by 1

-- pivoting a result set with subtotals:
-- query that for each department returns the managers in the department, and a sum of the salaries of the employees who work for those managers
-- inner query that reurn subtotals for the mgr from each dept:
select deptno, mgr, SUM(sal) as tot,
		cast(GROUPING(deptno) as varchar)+ cast(GROUPING(mgr) as varchar) as flag  --flag 00 is the result of standard grouping not subtotals
from emp
where mgr is not null
group by rollup(deptno,mgr)

--pivoting - by using CASE clause:
select mgr, 
		sum(case when deptno=10 then tot else '' end) as 'dep_10',
		sum(case when deptno=20 then tot else '' end) as 'dep_20',
		sum(case when deptno=30 then tot else '' end) as 'dep_30',
		sum(case when flag='11' then tot else '' end) as total
		--,flag
from (select deptno, mgr, SUM(sal) as tot,
		cast(GROUPING(deptno) as varchar)+ cast(GROUPING(mgr) as varchar) as flag  --flag 00 is the result of standard grouping not subtotals
	from emp
	--where mgr is not null
	group by rollup(deptno,mgr)) x
group by mgr
order by mgr desc

