CREATE PROCEDURE [dbo].[miLogProcedureError]
	@LogID INT
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @ErrorInfo NVARCHAR(4000);

	SET @ErrorInfo = 'Error Line: ' + CONVERT(nvarchar(5), ERROR_LINE()) + ' | '
                    + 'Error Message: ' + ERROR_MESSAGE();

	EXEC dbo.miLogProcedureErrorCLR @logID=@LogID, @errorInfo=@ErrorInfo;
	
END;