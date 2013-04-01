USE TableCheckTool
GO

CREATE TABLE ConnectionStrings(
	ConnectionID INT IDENTITY(1,1) PRIMARY KEY,
	ConnectionString VARCHAR(500),
	CategoryName VARCHAR(500)
)

CREATE TABLE TableRowCount(
	TableID INT,
	[Row Count] DECIMAL(20,2),
	[Timestamp] SMALLDATETIME DEFAULT getdate()
)

-- A TableID shouldn't exist if there's no matching ConnectionID
ALTER TABLE TableRowCount 
ADD CONSTRAINT FK_TableID
FOREIGN KEY (TableID) 
REFERENCES ConnectionStrings(ConnectionID)

-- Stored procedure will begin at approximately this point and should be called every minute

CREATE PROCEDURE sp_CheckTableCounts
AS
BEGIN

-- Dirty reads are acceptable
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Checks the row counts of tables listed in the ConnectionString table
DECLARE @start INT
SET @start = 1
DECLARE @total INT 
SELECT @total = MAX(ConnectionID) FROM ConnectionStrings
SET @total = @total + 1
DECLARE @sql NVARCHAR(MAX)

WHILE @start < @total
BEGIN
	DECLARE @conn NVARCHAR(500)
	SELECT @conn = ConnectionString FROM ConnectionStrings WHERE ConnectionID = @start
	
	SET @sql = 'INSERT INTO TableRowCount (TableID, [Row Count])
	SELECT ' + CAST(@start AS NVARCHAR(20)) +', COUNT(*)
	FROM ' + @conn

	EXECUTE(@sql)
	
	SET @start = @start + 1
END

-- Reporting on the row count change:
DECLARE @report TABLE(
	TableID INT,
	[Row Count] DECIMAL(20,2),
	Timestamp SMALLDATETIME
)

-- Get the last two minutes of row counts
INSERT INTO @report
SELECT *
FROM TableRowCount
WHERE Timestamp BETWEEN DATEADD(MI,-2,GETDATE()) AND GETDATE()

SELECT c.ConnectionString AS "Server and Table Name"
	,((t2.[Row Count]-t1.[Row Count])/(NULLIF(t1.[Row Count],0)))*100 AS "Delta"
	,t1.[Row Count], t2.[Row Count], t1.Timestamp, t2.Timestamp
FROM @report t1
	INNER JOIN @report t2 ON t1.TableID = t2.TableID AND t2.Timestamp = DATEADD(MI,+1,t1.Timestamp)
	INNER JOIN ConnectionStrings c ON t1.TableID = c.ConnectionID

END

/*

Another alternative way to establish connection strings using individual server, database, schema and table names:

CREATE TABLE ConnectionStrings(
	ConnectionID INT IDENTITY(1,1) PRIMARY KEY,
	ServerName VARCHAR(100),
	DatabaseName VARCHAR(100),
	SchemaName VARCHAR(100),
	TableName VARCHAR(100),
	ConnectionString VARCHAR(500)
)

INSERT INTO ConnectionStrings (ServerName,DatabaseName,SchemaName,TableName)
VALUES('[SERVERONE]','[dbone]','[dbo]','[TableOne]')
	,('[SERVERTWO]','[dbtwo]','[dob]','[TableTwo]')
	,('[SERVERTHREE]','[dbthree]','[bdo]','[TableThree]')

UPDATE ConnectionStrings
SET ConnectionString = ServerName + '.' + DatabaseName + '.' + SchemaName + '.' + TableName

CREATE PROCEDURE sp_CheckTableCounts
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @start INT
SET @start = 1
DECLARE @total INT 
SELECT @total = MAX(ConnectionID) FROM ConnectionStrings
SET @total = @total + 1
DECLARE @sql NVARCHAR(MAX)

WHILE @start < @total
BEGIN
	DECLARE @conn NVARCHAR(500)
	SELECT @conn = ConnectionString FROM ConnectionStrings WHERE ConnectionID = @start
	
	SET @sql = 'INSERT INTO TableRowCount (TableID, [Row Count])
	SELECT ' + CAST(@start AS NVARCHAR(20)) +', COUNT(*)
	FROM ' + @conn

	EXECUTE(@sql)
	
	SET @start = @start + 1
END

-- Reporting on the row count change:
DECLARE @report TABLE(
	TableID INT,
	[Row Count] DECIMAL(20,2),
	Timestamp SMALLDATETIME
)

-- Get the last two minutes of row counts
INSERT INTO @report
SELECT *
FROM TableRowCount
WHERE Timestamp BETWEEN DATEADD(MI,-2,GETDATE()) AND GETDATE()

SELECT c.ConnectionString AS "Server and Table Name"
	,((t2.[Row Count]-t1.[Row Count])/(NULLIF(t1.[Row Count],0)))*100 AS "Delta"
	,t1.[Row Count], t2.[Row Count], t1.Timestamp, t2.Timestamp
FROM @report t1
	INNER JOIN @report t2 ON t1.TableID = t2.TableID AND t2.Timestamp = DATEADD(MI,+1,t1.Timestamp)
	INNER JOIN ConnectionStrings c ON t1.TableID = c.ConnectionID

END

-- Will show the row counts by Table ID and date (pivotting data)

SELECT [Timestamp],
[1],[2],[3]
FROM (SELECT TableID, [Row Count], TimeStamp FROM TableRowCount) AS SourceTable
PIVOT
(
SUM([Row Count])
FOR TableID IN ([1],[2],[3]))
AS PivotTable;


*/
