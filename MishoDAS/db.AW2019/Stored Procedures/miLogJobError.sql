CREATE PROCEDURE [dbo].[miLogJobError]
	@jobId int,
	@errorInfo NVARCHAR(1000)
AS EXTERNAL NAME MishoClr.AutonomousTran.LogJobError;
