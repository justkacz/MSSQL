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

 --