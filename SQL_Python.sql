--STORED PROCEDURES:

sp_configure 'external scripts enabled', 1;
RECONFIGURE WITH OVERRIDE; 

EXECUTE sp_execute_external_script @language = N'Python'
    , @script = N'
a = 1
b = 2
c = a/b
d = a*b
print(c, d)';


EXECUTE sp_execute_external_script @language = N'Python'
    , @script = N'OutputDataSet = InputDataSet'
    , @input_data_1 = N'SELECT 1 AS hello'
WITH RESULT SETS(([Hello World] INT));
GO


CREATE TABLE PythonTestData (col1 INT NOT NULL)

INSERT INTO PythonTestData
VALUES (1);

INSERT INTO PythonTestData
VALUES (10);

INSERT INTO PythonTestData
VALUES (100);
GO

SELECT *
FROM PythonTestData


EXECUTE sp_execute_external_script @language = N'Python'
    , @script = N'OutputDataSet = InputDataSet;' -- commands passed to the Python runtime, also might be as a variable nvarchar
    , @input_data_1 = N'SELECT * FROM PythonTestData;' -- data returned by the query, passed to the Python runtime, which returns the data as a data fram
WITH RESULT SETS(([NewColName] INT NOT NULL));

--changing name of input and output variables:
EXECUTE sp_execute_external_script @language = N'Python',
	@script = N'SQL_out = SQL_in;', -- NEW NAMES, default input and output variable names are InputDataSet and OutputDataSet
	@input_data_1 = N'SELECT 12 as Col;',
	@input_data_1_name  = N'SQL_in', --define new variable names
    @output_data_1_name = N'SQL_out'
WITH RESULT SETS(([NewVarName] INT NOT NULL));
