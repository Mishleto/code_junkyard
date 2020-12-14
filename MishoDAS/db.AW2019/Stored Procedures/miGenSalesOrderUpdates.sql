CREATE PROCEDURE [dbo].[miGenSalesOrderUpdates]
	@GeneratedRows int = 3
AS
BEGIN
	
	SET NOCOUNT ON;
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	DECLARE @OrderIDs TABLE (ID INT);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		INSERT into @OrderIDs(ID)
		SELECT TOP(@GeneratedRows)
			SalesOrderID
		FROM Sales.SalesOrderHeader
		WHERE Status = 1 and ShipDate is null and OrderDate > DATEFROMPARTS(2020,10,10)
		ORDER BY OrderDate;

		UPDATE Sales.SalesOrderHeader
			set status = 5,
				ShipDate = GETDATE(),
				TaxAmt = 0.05 * SubTotal,
				Freight = 0.03 * SubTotal,
				ModifiedDate = GETDATE()
		WHERE SalesOrderID in (SELECT oi.ID FROM @OrderIDs oi);

		UPDATE Sales.SalesOrderDetail
			set CarrierTrackingNumber = CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4)) + dbo.miGetRandomAlphaNumString(10,1),
				ModifiedDate = GETDATE()
		WHERE SalesOrderID in (SELECT oi.ID FROM @OrderIDs oi);

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