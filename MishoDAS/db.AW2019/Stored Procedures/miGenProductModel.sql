CREATE PROCEDURE [dbo].[miGenProductModel]
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

		INSERT into Production.ProductModel(Name)
		SELECT 
			'ProductModel: ' + dbo.miGetRandomAlphaString(30,0)
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
