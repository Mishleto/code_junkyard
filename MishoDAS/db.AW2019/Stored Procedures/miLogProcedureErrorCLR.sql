CREATE PROCEDURE [dbo].[miLogProcedureErrorCLR]
	@logID INT,
	@errorInfo NVARCHAR(2000)
AS EXTERNAL NAME MishoClr.AutonomousTran.LogProcedureError;
