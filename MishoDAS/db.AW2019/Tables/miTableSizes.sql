CREATE TABLE [dbo].[miTableSizes]
(
	[StatsTime] DATETIME NOT NULL, 
    [SchemaName] NVARCHAR(128) NOT NULL,
	[TableName] NVARCHAR(128) NOT NULL, 
	[NumberOfRows] INT NOT NULL,
	[Used_MB] NUMERIC(36,2) NOT NULL, 
	[Unused_MB] NUMERIC(36,2) NOT NULL, 
	[Total_MB] NUMERIC(36,2) NOT NULL
)
