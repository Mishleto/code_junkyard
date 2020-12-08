CREATE PROCEDURE [dbo].[miGenProductInventory]
	@GeneratedRows int = 5
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

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