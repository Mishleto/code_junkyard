CREATE PROCEDURE [dbo].[miLogProcedureStart]
	@ProcedureID INT,
	@AdditionalInfo NVARCHAR(2000) = null,
	@LogID INT OUTPUT
AS
BEGIN
	DECLARE 
		@ProcedureName NVARCHAR(400),
		@CallerName NVARCHAR(128),
		@ParentLogID INT;

	 SELECT
		@ProcedureName = QUOTENAME(DB_NAME()) + '.'
			+ QUOTENAME(OBJECT_SCHEMA_NAME(@ProcedureID)) + '.'
			+ QUOTENAME(OBJECT_NAME(@ProcedureID)),
		@CallerName = CONVERT(nvarchar, user_name()),
		@ParentLogID = CONVERT(int, SESSION_CONTEXT(N'PARENT_LOG_ID'));

	EXEC @LogID = dbo.miLogProcedureStartCLR
		@procName = @ProcedureName,
		@objectID = @ProcedureID,
		@callerName = @CallerName,
		@parentLogID = @ParentLogID,
		@additionalInfo = @AdditionalInfo;
END;
