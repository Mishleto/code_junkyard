CREATE PROCEDURE [dbo].[miGenProductDescriptions]
	@GeneratedRows int = 1
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE 
		@LocalTranFlag BIT = 0,
		@LogID INT;
	
	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		INSERT into Production.ProductDescription(Description)
		SELECT 
			CASE 
				WHEN RndVal % 5 = 0 THEN 'ProdDescEN_' + dbo.miGetRandomAlphaString(30,0)
				WHEN RndVal % 5 = 1 THEN 'ProdDescFR_' + dbo.miGetRandomAlphaString(30,0)
				WHEN RndVal % 5 = 2 THEN 'ProdDescDE_' + dbo.miGetRandomAlphaString(30,0)
				WHEN RndVal % 5 = 3 THEN 'ProdDescRU_' + dbo.miGetRandomAlphaString(30,0)
				ELSE 'ProdDescCH_' + dbo.miGetRandomAlphaString(30,0)
			END
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