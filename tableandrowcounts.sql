CREATE TABLE ##normal (
  [Database Name] SYSNAME,
	[Table Name] SYSNAME,
	[Row Count] SYSNAME
)

-- Updates row count data
DBCC UPDATEUSAGE(0)

DECLARE @ServerTable TABLE(
	DatabaseID INT IDENTITY(1,1),
	DatabaseName VARCHAR(50)
)

DECLARE @count INT
DECLARE @start INT = 1
SELECT @count = COUNT(*) FROM sys.databases WHERE name NOT IN ('master','tempdb','model','msdb')

INSERT INTO @ServerTable (DatabaseName)
SELECT name 
FROM sys.databases
WHERE name NOT IN ('master','tempdb','model','msdb')

DECLARE @db VARCHAR(50)
DECLARE @sql NVARCHAR(4000)

WHILE @start < @count
BEGIN

	SELECT @db = DatabaseName FROM @ServerTable WHERE DatabaseID = @start
	
	SET @sql = 'INSERT INTO ##normal
	SELECT ''' + @db + '''
		,o.name
		,ddps.row_count
	FROM  ' + @db + '.sys.indexes AS i
		INNER JOIN ' + @db + ' .sys.objects AS o ON i.OBJECT_ID = o.OBJECT_ID
		INNER JOIN ' + @db + ' .sys.dm_db_partition_stats AS ddps ON i.OBJECT_ID = ddps.OBJECT_ID AND i.index_id = ddps.index_id 
	WHERE i.index_id < 2  AND o.is_ms_shipped = 0 
	ORDER BY o.NAME'
	
	EXECUTE(@sql)
	
	SET @start = @start + 1
END

SELECT *
FROM ##normal

CREATE TABLE ServerIdentifier(
	ServerID INT IDENTITY(1,1) NOT NULL,
	ServerName VARCHAR(200) NOT NULL
)

CREATE TABLE TableIdentifier(
	TableID INT IDENTITY(1,1) NOT NULL,
	TableName VARCHAR(200) NOT NULL,
	ServerID INT NOT NULL
)

CREATE TABLE #TableRowCount(
	OrderID BIGINT IDENTITY(1,1),
	TableID INT NOT NULL,
	[Catalog] VARCHAR(100),
	[Row Count] BIGINT,
	[Change] DECIMAL(5,2),
	[Timestamp] SMALLDATETIME
)

INSERT INTO #TableRowCount VALUES (1,'B',500,NULL,'2013-01-01'),(1,'B',750,NULL,'2013-01-02'),(1,'B',1000,NULL,'2013-01-03')

SELECT *
FROM #TableRowCount 

SELECT t1.*, t2.*
FROM #TableRowCount t1
	INNER JOIN #TableRowCount t2 ON t1.TableID = t2.TableID AND t1.OrderID = (t2.OrderID + 1)
	
SELECT (t1.[Row Count] - t2.[Row Count])
FROM #TableRowCount t1
	INNER JOIN #TableRowCount t2 ON t1.TableID = t2.TableID AND t1.OrderID = (t2.OrderID + 1)
	
