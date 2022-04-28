-- **********************************************HIERARCHICAL QUERIES:
-- self join that returns employees and their supervisors:
select e1.empno, e1.ename, coalesce(cast(e1.mgr as varchar), 'BOSS') as manager_no, coalesce(e2.ename, 'BOSS') as manager_name
from emp e1
	left join emp e2
		on e1.mgr=e2.empno


-- or by using scalar subquery in the select statement:
select e1.empno, e1.ename, e1.mgr, (select e2.ename from emp e2 where e2.empno=e1.MGR) as mgr_name
from emp e1

-- function that returns name of the employee's supervisor:
create function boss(@empname varchar(40))
returns varchar(40)
begin
declare @bossname varchar(40)
	set @bossname= (
		select e2.ename
			from emp e1
				left join emp e2
				on e1.mgr=e2.empno
			where e1.ENAME=@empname
		)
	return @empname+ ' manager is '+ @bossname
end

select dbo.boss('ALLEN')

-- building full hierarchy: Miller works for Clark and Clark works for King:
-- using CTE - starting from root -> King, employees whose manager is King...=> mgr= King's empno

with x(ename, empno)
as 
(
	select cast(ename AS varchar(max)), empno     -- cast columns in the initial query ehough -> important to use varchar(max) =>when the string length might exceed 8,000 bytes
	from emp
	where ename='King'
	union all 
	select x.ename  + ' -> ' + e.ename, e.empno
	from emp e, x
	where e.mgr=x.empno
 )
 select ename from x

 select ename + ' -> '+ ename
 from emp

 -- verifying if King is someone's manager:
 select ename, empno
 from emp
 where mgr=(select EMPNO from emp where ename='King')

 -- finding all child rows (employees who works for Jones directly and indirectly) => recursive CTE:
 with x (ename, empno)
 as
 (
	select ename, empno
	from emp
	where ename='JONES'
	union all
	select e.ename, e.empno
	from emp e, x
	where e.mgr=x.empno
 )
 select ename from x

--**************************************************PIVOT:
--standard way with CASE - counting the number of employees in each dept - inline view: 
select 
	max(case when deptno=10 then no else 0 end) as d_10,
	max(case when deptno=20 then no else 0 end) as d_20,
	max(case when deptno=30 then no else 0 end) as d_30
from
	(select deptno, count(*) no
	from emp
	group by deptno) x
-- or:
select 
	sum(case deptno when 10 then 1 else 0 end) as dept_10,
	sum(case deptno when 20 then 1 else 0 end) as dept_20,
	sum(case deptno when 30 then 1 else 0 end) as dept_30,
	sum(case deptno when 40 then 1 else 0 end) as dept_40
from emp

-- using PIVOT:
select [10] dept_10,
		[20] dept_20,
		[30] dept_30
from (select deptno, empno from emp) x
	pivot (count(x.empno) 
			for x.deptno in ( [10],[20],[30],[40] )) pivot_t


-- or with using dept names:
select [ACCOUNTING] as ACCOUNTING,
		[SALES] as SALES,
		[RESEARCH] as RESEARCH,
		[OPERATIONS] as OPERATIONS
from (select d.dname, e.empno
		from emp e, dept d
		where e.deptno=d.deptno) x
	pivot(count(x.empno)
			for x.dname in ([ACCOUNTING],[SALES],[RESEARCH],[OPERATIONS])) p_t


-- unpivoting:
-- the whole pivot clause as an inner query:
select dname, cnt
from (
		--pivot:
		select [ACCOUNTING] as ACCOUNTING,
				[SALES] as SALES,
				[RESEARCH] as RESEARCH,
				[OPERATIONS] as OPERATIONS
			from (select d.dname, e.empno
					from emp e, dept d
					where e.deptno=d.deptno) x
		pivot(count(x.empno)
			for x.dname in ([ACCOUNTING],[SALES],[RESEARCH],[OPERATIONS])) p_t ) p_t2
unpivot (cnt for dname in (ACCOUNTING,SALES,RESEARCH,OPERATIONS)) u_p


-- searching for mixed alphanumeric strings, query that returns rows where numeric and alphabetical characters exist:
select * from v8 --rows third and fourth should be returned

select strings
from (
	select strings,
	cast(TRANSLATE(strings, 'abcdefghijklmnopqrstuvwxyz1234567890', (REPLICATE('#', 26) + REPLICATE('*', 10))) as varchar(max)) t
	from v8) x
where t like '%#%' and t like '%*%'

-- Pivoting rank result set 1st column 3 the highest salaries, 2nd column next 3 salaries, 3rd column all the rest: :
--1) query that adds rank column:
select ename, sal, DENSE_RANK() over (order by sal desc)
from emp

--2) assigning values 1,2,3 to the rank numbers depending which rank group they belong to:
select ename, sal, dr, 
	case 
		when dr<=3 then 1
		when dr>3 and dr <=6 then 2
		when dr>6 then 3
	end as gr
from (
	select ename, sal, DENSE_RANK() over (order by sal desc) dr
	from emp
) x

--3) spreading 3 groups from inner query into 3 columns - top_3, next_3, rest:
select 
	max(case when gr=1 then ename +' ('+cast(sal AS varchar(max)) +')' end) as top_3,
	max(case when gr=2 then ename +' ('+cast(sal AS varchar(max)) +')' end) as next_3,
	max(case when gr=3 then ename +' ('+cast(sal AS varchar(max)) +')' end) as rest
from (select ename, sal, dr, 
	case 
		when dr<=3 then 1
		when dr>3 and dr <=6 then 2
		when dr>6 then 3
	end as gr,
	ROW_NUMBER() over (partition by case 
							when dr<=3 then 1
							when dr>3 and dr <=6 then 2
							when dr>6 then 3
						end
					order by sal) r  -- row number must be counted separately for each group, then row_number is used in the group by clause - otherwise the max()
from (									-- function in the outermost select statement would result with only one max value for each column
	select ename, sal, 
	DENSE_RANK() over (order by sal desc) dr
	from emp
) x ) y
group by r

-- breaking down the data into individual columns:
select * from v9

select strings,
	max(case when r=1 then value end) as 'col1',
	max(case when r=2 then value end) as 'col2',
	max(case when r=3 then value end) as 'col3',
	max(case when r=4 then value end) as 'col4'
from
	(select strings,  
	ROW_NUMBER() over(partition by strings order by strings) r, 
	value
	FROM v9 
		 CROSS APPLY STRING_SPLIT(strings, ':')
		 where LEN(value) !=0
		 ) x
group by strings


-- calculating percent relative to total:

select job, sal, cnt,
cast(cast(100 * cast(sal as numeric(15,2))/SUM(sal) over() as numeric(30,0))as varchar(max))+ '%' as pct_of_all_salaries
from (
	select job, SUM(sal) as sal, COUNT(empno) as cnt
	from emp
	group by job) x


-- query that marks with '+' students who passed at least one test within 3 consecutive months, if not - 
--the row that has the latest exam date for that student has a value of 1 for IN_PROGRESS
select * from v10

select x.*,
	case when sum=1 then '+' else '-' end as METREQ,
	case when sum=0 and test_date =max then 1 else 0 end as IN_PROGRESS
from (
	select student_id, test_id, grade_id, period_id, test_date, pass_fail,
		SUM(pass_fail) over(partition by period_id) as sum,
		MAX(test_date) over (PARTITION by period_id) as max
	from v10) x
order by test_date

-- **************************************************APPENDIX A
--when count does not have to be combined with group by:
select deptno, (select count(*) from emp) as cnt--, count (*) cnt_gr
from emp
--group by deptno

--or:
select deptno, (select count(*) from emp) as cnt, count (*) cnt_gr
from emp
group by deptno

--the same effect using window function:
select deptno, window_cnt, 
	count (*) cnt_gr
from (select *,							-- window function must be included in the inner statement, if in the outer - it would only count the number of groups (not the sum of items in each group) as grouping is before select
		count(*) over() as window_cnt
		from emp) x
group by deptno, window_cnt

-- determining rows used in the window functions:
select deptno, ename, sal, hiredate,
	SUM(sal) over (partition by deptno order by hiredate 
					rows between unbounded preceding and current row) as Total_1,  --from the first employee to current row
	SUM(sal) over (partition by deptno order by hiredate 
					rows between current row and unbounded following ) as Total_2,  -- from the last employee to current row
	SUM(sal) over (partition by deptno order by hiredate 
					rows between 1 preceding and 1 following ) as Total_3    -- one row behind and one row ahead the current row
from emp
order by deptno, hiredate

-- query that provides answers to the following questions:
--Who makes the highest salary of all employees (HI)
--Who makes the lowest salary of all employees (LO)
--Who makes the highest salary in the department (HIDPT)
--Who makes the lowest salary in the department (LODPT)
--Who makes the highest salary in their job (HIJOB)
--Who makes the lowest salary in their job (LOJOB)
--What is the sum of all salaries (TTL)
--What is the sum of salaries per department (DPTSUM)
--What is the running total of all salaries per department (DPTRT)

select deptno, ename, sal,
	max(sal) over() as HI,
	MIN(sal) over() as LO, 
	MAX(sal) over(partition by deptno) as HIDPT,
	min(sal) over(partition by deptno) as LODPT,
	MAX(sal) over(partition by job) as HIJOB,
	min(sal) over(partition by job) as LOJOB,
	sum(sal) over () as TTL,
	sum(sal) over(partition by deptno) as DPTSUM,
	sum(sal) over(partition by deptno order by empno) as DPTRT
from emp

--************************************************CTE:
with x (job, headcount)
as
(
	select job, COUNT(*) as headcount
	from emp
	group by job
)

--select * from x
select job, MAX(headcount)
from x
group by job

select job, max(cnt)
from (
	select job, COUNT(*) as cnt
	from emp
	group by job
	) x

group by job

-- Fibonacci:
with workingTable (fibNum, nextNumber, index1)
as
	(select 0,1,1
	union all
	select fibNum+nextNumber,fibNum,index1+1
		from workingTable
		where index1<20)

select fibNum from workingTable as fib
