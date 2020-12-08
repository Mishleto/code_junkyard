CREATE PROCEDURE [dbo].[miLogProcedureStartCLR]
	@procName NVARCHAR(400),
	@objectID INT,
	@callerName NVARCHAR(128),
	@parentLogID INT = null,
	@additionalInfo NVARCHAR(2000) = null
AS EXTERNAL NAME MishoClr.AutonomousTran.LogProcedureStart;