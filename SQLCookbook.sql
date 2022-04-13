select top 5 * from dept
select * from emp

-- find all the employees in department 10, along with any employees who earn a commission, along with any employees in department 20 who earn at most $2,000
select e.ename
from emp e
	left join dept d
	on e.deptno=d.deptno
where  e.deptno=10 or e.COMM is not null or (d.deptno=20 and E.comm >=2000)


-- using alias in the where clause - only by writing inner query in the from clause:
select *
from (select SAL as salary, COMM as commision FROM EMP) as s
where salary<5000

-- query that returns values in multiple columns as one column:
select ename +' works as a '+job
from emp
where deptno=10

-- IF-ELSE operations on values in your SELECT statement and limitation of the number of rows returned in the query:
select ename, sal, 
	case
	when sal<=2000 then 'underpaid'
	when sal > 4000 then 'overpaid'
	else 'OK' 
	end as status
from emp
order by sal
offset 0 rows
fetch next 5 rows only


-- return a specific number of random records from a table:
select ename, sal, comm
from emp
order by rand()
offset 0 rows
fetch first 5 rows only

--or:
select top 5 ename, sal, comm
from emp
order by newid()

--all rows that are null for a particular column, replace NULL with 0:
select coalesce(comm, 0) 
from emp

-- or with case:
select case
	when comm is null then 0
	else comm
	end 'comm with no null'
from emp

-- return rows that match a particular substring or pattern; employees in departments 10 and 20, you want to return only those that have
-- either an “I” somewhere in their name or a job title ending with “ER”:
select top 5* from emp

select ename, job
from emp
where deptno in (10,20)
	and (ename like '%I%' or job like '%ER')


-- **************************************************SORTING QUERY RESULTS:
-- if GROUP BY or DISTINCT is used in the query, with order by must be used column listed in the select statement
-- error in below query - comm should be in the select statement
select deptno, SUM(sal) from emp
group by deptno
order by comm

-- return employee names and jobs from table EMP and sort by the last two characters in the JOB field:
select ename, job, LEN(job), RIGHT(job, 2), SUBSTRING(job, len(job)-1, 2)
from emp
--order by RIGHT(job, 2) or:
order by SUBSTRING(job, len(job)-1, 2) --(2nd argument starting position, 3rd how many elements)

-- TRANSLATE(input_string, from_characters, to_characters) from and to must have the same number of items
select * from emp

create view v
as
select ename + ' ' + cast(deptno as varchar(5)) as d
from emp

-- order by concatenated string based on depno at the end of the string
select d from v
order by replace(d, replace( translate(d,'0123456789','##########'),'#',''),'')

-- 1) translate(d,'0123456789','##########') - replaces depno with #
-- 2) replace removes # - only string remains
-- 3) 2nd replace removes from d column string extracted by the first replace so only numbers remain

select ename, sal, coalesce(comm, 0) as COMM
from emp
order by comm

-- ordering null first and then descending order of not null values (helper column)
select ename, sal, comm
from (select ename, sal, comm, case
			when comm is null then 0 else 1
			end as is_null
			from emp) x
order by is_null, comm desc

--sorting on a data-dependent column:
--if JOB is SALESMAN, you want to sort on COMM; otherwise, you want to sort by SAL => case in the order by clause:
select ename, job, sal, comm
from emp
order by case 
		when job='Salesman' then comm else sal 
		end

-- or using case in the select statement:
select ename, job, sal, comm, case
			when job='Salesman' then comm else sal
			end as ordered
from emp
order by ordered


-- ************************************************WORKING WITH MULTPLE TABLES:
--display the name and department number of the employees in department 10 in table EMP, along with the name and department number of each department in table DEPT.
select ename, deptno
from emp
where deptno =10
union all
select dname, deptno
from dept

-- join with multiple columns:
create view V2 as
select ename,job,sal
from emp
where job = 'CLERK'

select e.empno, e.ename, e.job, e.sal, e.deptno
from emp as e
	join V1 as v 
	on (e.ename=v.ename and
		e.job=v.job and
		e.sal=v.sal
	)

--In SQL, “TRUE or NULL” is TRUE, but “FALSE or NULL” is NULL!