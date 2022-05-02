

create table emp(EMPNO int, ENAME varchar(40), JOB varchar(40), MGR int, HIREDATE datetime, SAL int, COMM int, DEPTNO int);
go

insert into emp values(7654, 'MARTIN', 'SALESMAN', 7698, '28-SEP-2006', 1250, 1400, 30),
					(7499, 'ALLEN', 'SALESMAN', 7698 ,'20-FEB-2006', 1600, 300 ,30),
					(7521, 'WARD', 'SALESMAN' ,7698 ,'22-FEB-2006', 1250 ,500, 30),
					(7844, 'TURNER', 'SALESMAN', 7698, '08-SEP-2006' ,1500 ,0 ,30)

insert into emp(EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, DEPTNO)  values(7369, 'SMITH', 'CLERK', 7902, '17-DEC-2005',800, 20),
																		(7566, 'JONES', 'MANAGER', 7839, '02-APR-2006', 2975, 20),
																		(7698, 'BLAKE', 'MANAGER', 7839, '01-MAY-2006', 2850 ,30),
																		(7782, 'CLARK', 'MANAGER', 7839 ,'09-JUN-2006', 2450, 10),
																		(7788, 'SCOTT', 'ANALYST', 7566, '09-DEC-2007', 3000 ,20),
																		(7876, 'ADAMS' ,'CLERK' ,7788, '12-JAN-2008', 1100 ,20),
																		(7900, 'JAMES' ,'CLERK' ,7698, '03-DEC-2006', 950, 30),
																		(7902, 'FORD', 'ANALYST', 7566 ,'03-DEC-2006' ,3000 ,20),
																		(7934, 'MILLER' ,'CLERK' ,7782, '23-JAN-2007' ,1300, 10)

insert into emp(EMPNO, ENAME, JOB, HIREDATE, SAL, DEPTNO)  values (7839, 'KING', 'PRESIDENT', '17-NOV-2006' ,5000 ,10)

create table dept(DEPTNO int, DNAME varchar(40),LOC varchar(40));
go

insert into dept values (10, 'ACCOUNTING', 'NEW YORK'),
						(20, 'RESEARCH', 'DALLAS'),
						(30, 'SALES', 'CHICAGO'),
						(40, 'OPERATIONS', 'BOSTON')

create table emp_bonus(empno int, received datetime, type int);
go

insert into emp_bonus values (7934,	'2005-03-17', 1),
							(7934,	'2005-03-15', 2),
							(7839,	'2005-02-15', 3),
							(7782,	'2005-02-15', 1)



create table emp3(EMPNO int, ENAME varchar(40), JOB varchar(40), MGR int, HIREDATE datetime, SAL int, COMM int, DEPTNO int);
go

insert into emp3 values(7654, 'MARTIN', 'SALESMAN', 7698, '28-SEP-2006', 1250, 1400, 30),
					(7499, 'ALLEN', 'SALESMAN', 7698 ,'20-FEB-2006', 1600, 300 ,30),
					(7521, 'WARD', 'SALESMAN' ,7698 ,'22-FEB-2006', 1250 ,500, 30),
					(7844, 'TURNER', 'SALESMAN', 7698, '08-SEP-2006' ,1500 ,0 ,30)

insert into emp3(EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, DEPTNO)  values(7369, 'SMITH', 'CLERK', 7902, '17-DEC-2005', 800, 20),
																		(7566, 'JONES', 'MANAGER', 7839, '02-APR-2006', 2975, 20),
																		(7698, 'BLAKE', 'MANAGER', 7839, '01-MAY-2006', 2850 ,30),
																		(7782, 'CLARK', 'MANAGER', 7839 ,'09-JUN-2006', 2450, 10),
																		(7788, 'SCOTT', 'ANALYST', 7566, '09-DEC-2007', 3000 ,20),
																		(7876, 'ADAMS' ,'CLERK' ,7788, '12-JAN-2008', 1100 ,20),
																		(7900, 'JAMES' ,'CLERK' ,7698, '03-DEC-2006', 950, 30),
																		(7902, 'FORD', 'ANALYST', 7566 ,'03-DEC-2006' ,3000 ,20),
																		(7934, 'MILLER' ,'CLERK' ,7782, '23-JAN-2007' ,1300, 10)

insert into emp3(EMPNO, ENAME, JOB, HIREDATE, SAL, DEPTNO)  values (7839, 'KING', 'PRESIDENT', '17-NOV-2006' ,5000 ,10)

insert into emp3 (empno,ename,deptno,sal,hiredate)
values (1,'ant',10,1000,'17-NOV-2006')
insert into emp3 (empno,ename,deptno,sal,hiredate)
values (2,'joe',10,1500,'17-NOV-2006')
insert into emp3 (empno,ename,deptno,sal,hiredate)
values (3,'jim',10,1600,'17-NOV-2006')
insert into emp3 (empno,ename,deptno,sal,hiredate)
values (4,'jon',10,1700,'17-NOV-2006')



create table range(proj_id int, proj_s datetime, proj_e datetime)
go

insert into range values (1 ,'01-JAN-2020', '02-JAN-2020'),
						 (2 ,'02-JAN-2020', '03-JAN-2020'),
						 (3 ,'03-JAN-2020', '04-JAN-2020'),
						 (4 ,'04-JAN-2020', '05-JAN-2020'),
						 (5 ,'06-JAN-2020', '07-JAN-2020'),
						 (6 ,'16-JAN-2020', '17-JAN-2020'),
						 (7 ,'17-JAN-2020', '18-JAN-2020'),
						 (8 ,'18-JAN-2020', '19-JAN-2020'),
						 (9 ,'19-JAN-2020', '20-JAN-2020'),
						 (10, '21-JAN-2020', '22-JAN-2020'),
						 (11, '26-JAN-2020', '27-JAN-2020'),
						 (12, '27-JAN-2020', '28-JAN-2020'),
						 (13, '28-JAN-2020', '29-JAN-2020'),
						 (14, '29-JAN-2020', '30-JAN-2020')



create table IT_research (deptno int, ename varchar(20))
go

insert into IT_research values (100,'HOPKINS')
insert into IT_research values (100,'JONES')
insert into IT_research values (100,'TONEY')
insert into IT_research values (200,'MORALES')
insert into IT_research values (200,'P.WHITAKER')
insert into IT_research values (200,'MARCIANO')
insert into IT_research values (200,'ROBINSON')
insert into IT_research values (300,'LACY')
insert into IT_research values (300,'WRIGHT')
insert into IT_research values (300,'J.TAYLOR')

create table IT_apps (deptno int, ename varchar(20))
go
insert into IT_apps values (400,'CORRALES')
insert into IT_apps values (400,'MAYWEATHER')
insert into IT_apps values (400,'CASTILLO')
insert into IT_apps values (400,'MARQUEZ')
insert into IT_apps values (400,'MOSLEY')
insert into IT_apps values (500,'GATTI')
insert into IT_apps values (500,'CALZAGHE')
insert into IT_apps values (600,'LAMOTTA')
insert into IT_apps values (600,'HAGLER')
insert into IT_apps values (600,'HEARNS')
insert into IT_apps values (600,'FRAZIER')
insert into IT_apps values (700,'GUINN')
insert into IT_apps values (700,'JUDAH')
insert into IT_apps values (700,'MARGARITO')

-- ************************************************************VIEWS:
create view d  
as  
select ename + cast(sal as varchar(10)) as data  
from emp 

create view pivot_dept
as
select
	sum(case when deptno=10 then 1 else null end) as dept_10,
	sum(case when deptno=20 then 1 else null end) as dept_20,
	sum(case when deptno=30 then 1 else null end) as dept_30
from emp

create view v  
as  
select ename + ' ' + cast(deptno as varchar(5)) as d  
from emp

create view V1 as  
select ename,job,sal  
from emp  
where job = 'CLERK'

create view V2 as  
select ename,job,sal  
from emp  
where job = 'CLERK'


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

create view V4 as  
select e.ename + ' ' + cast(e.empno as varchar(10)) + ' ' + d.dname as data  
from emp e, dept d  
 where e.deptno=d.deptno



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

create view v6 as  
select deptno, STRING_AGG(ename, ', ') agg_name  
from emp  
group by deptno  



create view V7 (id,amt,trx)  
as  
select 1, 100, 'PR' union all  
select 2, 100, 'PR'  union all  
select 3, 50, 'PY' union all  
select 4, 100, 'PR' union all  
select 5, 200, 'PY' union all  
select 6, 50, 'PY' 

create view V8 as
(
	select 'ClassSummary' strings
	union all
	select '3453430278'
	union all
	select 'findRow 55'
	union all
	select '1010 switch'
	union all
	select '333'
	union all
	select 'threes'
)

create view v9
as (
select 'entry:stewiegriffin:lois:brian:' strings
union all
select 'entry:moe::sizlack:'
union all
select 'entry:petergriffin:meg:chris:'
union all
select 'entry:willie:'
union all
select 'entry:quagmire:mayorwest:cleveland:'
union all
select 'entry:::flanders:'
union all
select 'entry:robo:tchi:ken:'
)

create view V10
as
	select 1 student_id,
	1 test_id,
	2 grade_id,
	1 period_id,
	cast('02/01/2020' as datetime) test_date,
	0 pass_fail
	 union all
	select 1, 2, 2, 1, cast('03/01/2020' as datetime), 1 union all
	select 1, 3, 2, 1, cast('04/01/2020' as datetime), 0 union all
	select 1, 4, 2, 2, cast('05/01/2020' as datetime), 0 union all
	select 1, 5, 2, 2, cast('06/01/2020' as datetime), 0 union all
	select 1, 6, 2, 2, cast('07/01/2020' as datetime), 0 

