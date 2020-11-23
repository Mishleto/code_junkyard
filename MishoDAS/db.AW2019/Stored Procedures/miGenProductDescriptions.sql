CREATE PROCEDURE [dbo].[miGenProductDescriptions]
	@GeneratedRows int = 1
AS
BEGIN

	DECLARE @localTran BIT = 0;
	
	BEGIN TRY

		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
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

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;
		
		EXECUTE [dbo].[uspLogError];
		RETURN -1
	END CATCH

	RETURN 0
END;