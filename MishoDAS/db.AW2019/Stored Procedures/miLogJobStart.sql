CREATE PROCEDURE [dbo].[miLogJobStart]
	@jobName NVARCHAR(50),
	@parentID int = null,
	@jobInfo NVARCHAR(1000)
AS EXTERNAL NAME MishoClr.AutonomousTran.LogJobStart;
