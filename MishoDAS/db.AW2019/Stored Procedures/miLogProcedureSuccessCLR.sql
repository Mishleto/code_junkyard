CREATE PROCEDURE [dbo].[miLogProcedureSuccessCLR]
	@logID INT
AS EXTERNAL NAME MishoClr.AutonomousTran.LogProcedureSuccess;