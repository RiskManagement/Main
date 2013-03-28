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
