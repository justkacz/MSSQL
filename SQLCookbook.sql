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

-- EXIST/NOT EXISTS:
-- If the subquery returns results, then EXISTS (…) evaluates to true and NOT EXISTS (…) thus evaluates to FALSE, and the row being considered by the outer query is discarded.
-- If the subquery returns no results, then NOT EXISTS (…) evaluates to TRUE, and the row being considered by the outer query is returned (because it is for a department not represented in the EMP table)


--return the name of each employee in department 10 along with the location of the department
select e.ename, d.loc
from emp e
left join dept d
on e.deptno=d.deptno
where e.deptno=10

-- or:
select e.ename, d.loc
from emp e, dept d
where e.deptno=10
	and e.deptno=d.deptno -- without this equation the result would have been incorrect => eCartesian product, with more rows

-- find the sum of the salaries for employees in department 10 along with the sum of their bonuses:
select * from emp

select e.empno, e.ename, e.sal, e.deptno, 
	e.sal* case 
			when eb.typre=1 then 0.1
			when eb.typre=2 then 0.2
			when eb.typre=3 then 0.3
		end as bonus
from emp e
left join emp_bonus eb
on eb.empno=e.empno 
where e.deptno=10

-- total sal & bonus for deptno = 10:
-- important to add distinct with aggregate functions and joins to avoid rows duplication: 

select x.deptno, SUM(distinct(x.sal)) as sum_sal, SUM(x.bonus) as sum_bonus
from 
	(select e.empno, e.ename, e.sal, e.deptno, 
		e.sal* case 
			when eb.typre=1 then 0.1
			when eb.typre=2 then 0.2
			when eb.typre=3 then 0.3
		end as bonus
	from emp e
		left join emp_bonus eb
			on eb.empno=e.empno 
		where e.deptno=10) as x
group by x.deptno

-- or second solution: the sum of the salary is computed first then tables are joined (using from and where clauses):
select e.deptno, total_sal,
	sum(e.sal*case when eb.typre = 1 then .1
					when eb.typre = 2 then .2
					else .3 end) as total_bonus
from emp e, 
	emp_bonus eb,
	(select deptno, SUM(sal) as total_sal
	from emp
	where deptno=10
	group by deptno) d  -- avoiding join statement, the sum of the salary is computed until tables are joined (sum returns correct value - its alias is used in the outer general query)
where e.empno=eb.empno
	and d.deptno=e.deptno
group by e.deptno, total_sal

-- new table with only two employees from  department 10 who got bonus:
select * from emp_bonus2

select e.deptno, total_sal,
	sum(e.sal*case when eb.type = 1 then .1
					when eb.type = 2 then .2
					else .3 end) as total_bonus
from emp e, 
	emp_bonus2 eb,
	(select deptno, SUM(sal) as total_sal
	from emp
	where deptno=10
	group by deptno) d  -- avoiding join statement, the sum of the salary is computed until tables are joined (sum returns correct value - its alias is used in the outer general query)
where e.empno=eb.empno
	and d.deptno=e.deptno
group by e.deptno, total_sal

--query that finds all employees in EMP whose commission (COMM) is less than the commission of employee WARD. Employees with a NULL commission should be included as well
declare @ward int = (select comm from emp where ename = 'WARD')
--select @ward

select ename, comm
from emp
where comm < @ward
or comm is null

-- or with using coalesce to turn null values into 0  and then it is possible to compare comm column with variable:
declare @ward int = (select comm from emp where ename = 'WARD')
select ename, comm
from emp
where coalesce(comm, 0) < @ward


--**************************************************************************INSERTING, UPDATING, AND DELETING
-- inserting efault values (PostgreSQL and SQL Server):
create table animal (id int, species varchar (20) default 'cat')
insert into animal values(1, 'dog'),
						(2, default)

select * from animal
-- By specifying NULL as the value for a column, he column can be set to NULL despite any default value

-- copying data into new table:

-- 1) the empty new table must be earlier created:

-- creating new table with copying column structure of existing table (without rows) by using a subquery that returns no rows:.

select *
into DEPT_EAST1
from dept
	where 1=0

--PostgreSQL:
--create table dept_2
--as
--select *
--from dept
--where 1 = 0

insert into DEPT_EAST1
select *
from dept

-- no need to create table earlier, all rows from dept table are copied:
select * 
into DEPT_EAST2
from dept

select * from DEPT_EAST2

-- blocking inerts to certain columns - creating view with desired columns and inserting values to the view (the original table will be also populated with new values)

-- update rows in one table when corresponding rows exist in another - change salary only for the employees who exist in the emp table:
update emp
set sal =sal * 1.2
where empno in (select empno from emp_bonus)

--or with EXISTS:
select * from emp
where exists (select * from emp_bonus where emp.empno=emp_bonus.empno) 

-- query that updates the salaries and commission of certain employees in table EMP using values table NEW_SAL if there is a match between EMP.DEPTNO and NEW_SAL.DEPTNO,
-- update EMP.SAL to NEW_SAL.SAL, and update EMP.COMM to 50% of NEW_SAL.SAL
select * from emp where deptno =10
select * from new_sal

begin tran test

update e
	set e.sal=ns.sal,
		e.comm=ns.sal*0.5
	from emp e, new_sal ns
	where e.deptno=ns.deptno

rollback tran test

select * from emp e where exists(select * from new_sal ns where e.deptno=ns.deptno)

-- or using merge:
begin tran test2

merge into emp as trg
using new_sal as src
on trg.deptno=src.deptno
	when matched then 
		update set
		trg.sal=src.sal,
		trg.comm=src.sal*0.5;
		--delete where mgr<=7839

-- deleting duplicated rows:
select * from dupes order by 1

begin tran del1
delete from dupes
where id not in (select min(id) from dupes group by name)
rollback tran del1

-- or with count statement 
begin tran del2
delete from dupes where name in (select name from dupes group by name having count(*)>1)
rollback tran del2

