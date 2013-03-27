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
