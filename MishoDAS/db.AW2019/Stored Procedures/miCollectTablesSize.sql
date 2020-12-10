CREATE PROCEDURE [dbo].[miCollectTablesSize]
AS
BEGIN
	DECLARE 
		@SqlCmd NVARCHAR(MAX),
		@dtNow DATETIME = GETDATE();
	DECLARE @ResTable TABLE (ObjectID INT, NumberOfRows INT);

	with preprocess as 
	(
		SELECT (N'SELECT ' 
				+ CONVERT(NVARCHAR(15), t.object_id) + N' as ObjectID, '
				+ N'count(*) as NumberOfRows '
				+ N'FROM ' + s.name + '.' + t.name) as SelectSql
		FROM sys.tables t
			inner join sys.schemas s on t.schema_id = s.schema_id
		WHERE s.schema_id > 4			-- exclude dbo, guest, sys, INFORMATION_SCHEMA
			and s.schema_id < 16384		-- exclude other system schemas
	)
	SELECT @SqlCmd = STRING_AGG( CONVERT(NVARCHAR(MAX), SelectSql), N' UNION ALL ')
	FROM preprocess;

	INSERT into @ResTable
	EXEC sp_executesql @SqlCMD;

	with disk_sizes as
	(
		SELECT
			s.name as SchemaName,
			t.name as TableName,
			t.object_id AS ObjectID,
			CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Used_MB,
			CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Unused_MB,
			CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Total_MB
		FROM sys.tables t
			INNER JOIN sys.indexes i ON t.object_id = i.object_id
			INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
			INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
			inner join sys.schemas s on s.schema_id = t.schema_id
		GROUP BY t.object_id, t.name, s.name
	)
	INSERT into dbo.miTableSizes
	SELECT 
		@dtNow,
		[ds].[SchemaName], 
		[ds].[TableName], 
		[rt].[NumberOfRows],
		[ds].[Used_MB], 
		[ds].[Unused_MB], 
		[ds].[Total_MB]
	FROM disk_sizes ds 
		inner join @ResTable rt on rt.ObjectID = ds.ObjectID;

END;
