-- ******************************************************ADVANCED SEARCHING:
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
select e.ename, d.deptno, d.dname, d.loc
from dept d
	left join emp e
		on e.deptno=d.deptno and (e.deptno =10 or e.deptno = 20)   -- emp table is filtered and to the whole dept table are joined only records from 10 or 20 department
order by d.deptno

--or:
select e.ename, d.deptno, d.dname, d.loc
from dept d							-- to the whole dept tablt with all departments is attached emp table only with deptno 10 or 20
	left join
		(select ename, deptno
		from emp
		where deptno in ( 10, 20 )
		) e on ( e.deptno = d.deptno )
order by 2

-- selecting the top n records:
--using window function rank/dense_rank() -> counts the same sal value for multiple emp as a one record:
select ename, sal, r
from (select ename, sal,
	RANK() over(order by sal) as r
	from emp) x
where r<=10

-- or with top ties: the same result as using rank(), more records returned when using dense_rank()
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

-- shifting row values, query that returns ach employee’s name and salary along with the next highest and lowest salaries:
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

-- ranking results: