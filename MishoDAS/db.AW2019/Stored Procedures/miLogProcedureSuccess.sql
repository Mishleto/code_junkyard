﻿CREATE PROCEDURE [dbo].[miLogProcedureSuccess]
	@LogID int
AS
BEGIN
	SET NOCOUNT ON;
	
	EXEC dbo.miLogProcedureSuccessCLR @logID=@LogID;

END;
