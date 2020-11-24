CREATE PROCEDURE [dbo].[miGenProductInventory]
	@GeneratedRows int = 5
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE @localTran BIT = 0;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

		MERGE 
		into Production.ProductInventory as target
		USING
		(
			SELECT TOP (@GeneratedRows)
				ProductID,
				LocationID
			FROM Production.ProductInventory
			ORDER BY ModifiedDate asc
		) as source
		on target.ProductID = source.ProductID
			and target.LocationID = source.LocationID
		WHEN MATCHED THEN
			UPDATE set 
				target.Quantity = target.Quantity * ( 1 + 0.1*dbo.miGetRandomInt32(-1,3)),
				target.ModifiedDate = GETDATE()
		;

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;

		EXEC dbo.uspLogError;
		RETURN -1;
	END CATCH

RETURN 0
END;

