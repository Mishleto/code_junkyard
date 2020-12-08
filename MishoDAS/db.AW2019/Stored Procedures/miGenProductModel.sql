CREATE PROCEDURE [dbo].[miGenProductModel]
	@GeneratedRows int = 1
AS
BEGIN

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;
	
	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into Production.ProductModel(Name)
		SELECT 
			'ProductModel: ' + dbo.miGetRandomAlphaString(30,0)
		FROM dbo.miGetRandomIntTable(@GeneratedRows, 0, 1000);

		IF @LocalTranFlag=1
			COMMIT;

		EXEC dbo.miLogProcedureSuccess @LogID;

	END TRY

	BEGIN CATCH
		IF @LocalTranFlag=1
			ROLLBACK;

		EXEC dbo.miLogProcedureError @LogID;
		RETURN -1;
	END CATCH

	RETURN 0;
END;