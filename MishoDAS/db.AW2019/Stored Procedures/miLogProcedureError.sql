CREATE PROCEDURE [dbo].[miLogProcedureError]
	@LogID INT
AS
BEGIN
	
	DECLARE @ErrorInfo NVARCHAR(2000);

	--TODO set @ErrorInfo

	EXEC dbo.miLogProcedureErrorCLR @LogID, @ErrorInfo;
	
END;
