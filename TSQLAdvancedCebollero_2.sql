-- TRIGGERS:
-- action indicators: INSTEAD OF and AFTER/FOR
-- ON VIEWS - might be used only INSTEAD OF
-- DML events CANNOT BE executed on: temporary tables, memory tables and table variables
-- parameters are not available

--listing all DDL, DML events that might be used as trigger events:

select * from sys.trigger_event_types

-- listing all triggers using view sys.triggers:
SELECT
name,
OBJECT_SCHEMA_NAME(parent_id) + '.' + OBJECT_NAME(parent_id) as Parent
FROM sys.triggers
-- WHERE is_disabled =1  -- filtering out only those that are disabled

-- deleting trigger: <schema_name><trigger_name>
drop trigger HumanResources.timeupdate


-- trigger that updates ModifiedDate column with current date when any row in the table is modified:
create trigger timeupdate
on [HumanResources].[Employee]  --table on which trigger will be activated
after update
not for replication   --events related to replication will not activate trigger
as
begin
	if @@ROWCOUNT=0 return    -- stop trigger when no row has been modified

	set nocount on   -- turns off messages 'rows affected'
	update [HumanResources].[Employee]
	set ModifiedDate=GETDATE()    -- column ModifiedDate will be updated with current date and time
	where exists
	(
		select 1
		from inserted i  -- inserted = virtual tables: inserted and deleted; tables that have the same structure (columns) that table on which trigger has been activated, they store only records that has been modfied, in case of update = old data in delete table, new data in insert table 
		where i.BusinessEntityID=HumanResources.Employee.BusinessEntityID
	);
end

IF OBJECT_ID ('timeupdate', 'TR') IS NOT NULL  
   DROP TRIGGER [timeupdate];  

UPDATE HumanResources.Employee
SET MaritalStatus = 'W'
WHERE BusinessEntityID IN (1, 2, 3);

-- ModifiedDate column has been updated with current date:
select * from [HumanResources].[Employee]
WHERE BusinessEntityID IN (1, 2,3);

-- TRIGGER that returns more details about INSERTED/DELETED/UPDATED ROWS and populate table DmlActionLog:
create trigger auditInf 
on HumanResources.Employee
after insert, delete, update
not for replication
as
begin
	if @@ROWCOUNT=0 return;

	set nocount on;
	
	declare @inserted_cnt int = (select COUNT(*) from inserted)  --number of inserted rows
	declare @deleted_cnt int = (select COUNT(*) from deleted)  --number of deleted rows
	
	declare @actionType varchar(40) = case
							when (@inserted_cnt>0) and (@deleted_cnt=0) then 'inserted'
							when (@inserted_cnt=0) and (@deleted_cnt>0) then 'deleted'
							else 'updated'
					  end;
		
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'DmlActionLog')
		BEGIN
		    insert into DmlActionLog--(schama_name, obj_name, action_type, userName, appName, hostName)
			SELECT
			OBJECT_SCHEMA_NAME(@@PROCID, DB_ID()),
			OBJECT_NAME(t.parent_id, DB_ID()),
			@ActionType as action_type,
			SUSER_SNAME(),
			APP_NAME(),
			HOST_NAME() 
			from sys.triggers t
			WHERE t.object_id = @@PROCID;
		END
		else
		begin
			SELECT
				OBJECT_SCHEMA_NAME(@@PROCID, DB_ID()) as schama_name,
				OBJECT_NAME(t.parent_id, DB_ID()) as obj_name,
				@ActionType as action_type,
				SUSER_SNAME() as userName,
				APP_NAME() as appName,
				HOST_NAME() as hostName
				into dbo.DmlActionLog
			from sys.triggers t
				WHERE t.object_id = @@PROCID
		end
end


select * from dbo.DmlActionLog2

-- INSTEAD OF TRIGGER - allows to skip an INSERT, DELETE, or UPDATE statement to a table or a view and execute other statements defined in the trigger instead
-- The actual insert, delete, or update operation does not occur at all
-- the most popular use case - to override an insert, update, or delete operation on a view



