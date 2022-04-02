--***********************************************WINDOW FUNCTIONS:
--computes a scalar result value based on a calculation against a subset of the rows from the underlying query. The subset of rows is known as a window
-- clause OVER, in which you provide the window specification
-- it performs a calculation against a set and returns a single value.
-- parts of the window specification in the OVER clause: partitioning, ordering and framing

--the starting point of a window function is the underlying query’s result set, and the underlying query’s result set is generated only when the SELECT phase is reached, window
-- functions are allowed only in the SELECT and ORDER BY clauses of a query. If there is a need to refer to a window function in an earlier logical query processing phase (such as WHERE), the table expression must be used
-- NTILE - divides the entire table on equal groups specified by the number of ntile 
-- DISTINCT in select clause does not work, first the unique row numbers are assigned then the distinct clause see that all rows are unique - > solution: using group by (it evaluates before select statement so unique row numbers are assigned to groups)
--  

--query that uses a window aggregate function to compute the running total values for each employee and month
select top 5 * from [Sales].[EmpOrders]

select empid, ordermonth, val,
	SUM(val) over(partition by empid
					order by ordermonth
					rows between unbounded preceding and current row) as run_val
from [Sales].[EmpOrders]

-- using gruop by to achieve distinct values:
select val, ROW_NUMBER() over(order by val) as rownum
from [Sales].[OrderValues]
group by val   -- before select statement, rows are assigned to already grouped values

