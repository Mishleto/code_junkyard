CREATE PROCEDURE [dbo].[miLogJobSuccess]
	@jobId int
AS EXTERNAL NAME MishoClr.AutonomousTran.LogJobSuccess;
