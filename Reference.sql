USE TableCheckTool
GO

CREATE TABLE ConnectionStrings(
  ConnectionID INT IDENTITY(1,1) PRIMARY KEY,
	ConnectionString VARCHAR(500),
	CatalogName VARCHAR(500)
)

CREATE TABLE TableRowCount(
	TableID INT PRIMARY KEY,
	[Row Count] DECIMAL(20,2),
	[Timestamp] SMALLDATETIME
)

ALTER TABLE TableRowCount 
ADD CONSTRAINT FK_TableID
FOREIGN KEY (TableID) 
REFERENCES ConnectionStrings(ConnectionID)

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

-- Reporting:
DECLARE @report TABLE(
	TableID INT,
	[Row Count] DECIMAL(20,2),
	Timestamp SMALLDATETIME
)

INSERT INTO @report
SELECT *
FROM TableRowCount
WHERE Timestamp BETWEEN DATEADD(MI,-5,GETDATE()) AND GETDATE()

SELECT ((t2.[Row Count]-t1.[Row Count])/(NULLIF(t1.[Row Count],0)))*100 AS "Delta"
	,t1.[Row Count], t2.[Row Count], t1.Timestamp, t2.Timestamp
FROM @report t1
	INNER JOIN @report t2 ON t1.TableID = t2.TableID AND t2.Timestamp = DATEADD(MI,+1,t1.Timestamp)
