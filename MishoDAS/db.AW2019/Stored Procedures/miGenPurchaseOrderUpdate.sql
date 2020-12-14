CREATE PROCEDURE [dbo].[miGenPurchaseOrderUpdate]
	@GeneratedRows int = 5
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	DECLARE	@PurchaseOrders TABLE (ID INT);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		INSERT into @PurchaseOrders
		SELECT TOP (@GeneratedRows)
			poh.PurchaseOrderID
		FROM Purchasing.PurchaseOrderHeader poh
		WHERE poh.Status = 2
			and poh.OrderDate > DATEADD(month, -3, GETDATE())
			and poh.ShipDate > GETDATE()
		ORDER BY DATEDIFF(day, poh.ShipDate, GETDATE()) asc;

		WITH tbl as
		(
			SELECT 
				OrderQty,
				ReceivedQty,
				RejectedQty,
				ModifiedDate,
				dbo.miGetRandomInt32(0, OrderQty -3) as Rejects
			FROM Purchasing.PurchaseOrderDetail
			WHERE PurchaseOrderID in (SELECT ID FROM @PurchaseOrders)
		)
		UPDATE tbl
			SET ReceivedQty = OrderQty - Rejects,
				RejectedQty = Rejects,
				ModifiedDate = GETDATE();

		UPDATE Purchasing.PurchaseOrderHeader
			set Status = 4,
				TaxAmt = 5*SubTotal/100.00,
				Freight = 2*SubTotal / 100.00,
				ModifiedDate = GETDATE()
		WHERE PurchaseOrderID in (SELECT ID FROM @PurchaseOrders);

		DELETE FROM @PurchaseOrders; 

		INSERT into @PurchaseOrders
		SELECT TOP (@GeneratedRows)
			poh.PurchaseOrderID
		FROM Purchasing.PurchaseOrderHeader poh
		WHERE poh.Status = 1
			and poh.OrderDate > DATEADD(month, -3, GETDATE())
			and poh.ShipDate > GETDATE()
		ORDER BY DATEDIFF(day, poh.ShipDate, GETDATE()) asc;

		UPDATE Purchasing.PurchaseOrderHeader 
			SET Status = 2,
				ModifiedDate = GETDATE()
		WHERE PurchaseOrderID in (SELECT ID FROM @PurchaseOrders);

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