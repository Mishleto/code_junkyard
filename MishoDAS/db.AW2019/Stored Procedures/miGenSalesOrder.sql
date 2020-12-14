CREATE PROCEDURE [dbo].[miGenSalesOrder]
	@GeneratedRows int = 3
AS
BEGIN
	
	SET NOCOUNT ON;

	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT,
		@orderDetailsCount TINYINT,
		@isOnline BIT;

	DECLARE @OrderIDs TABLE (ID INT);
	

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		SET @isOnline = dbo.miGetRandomInt32(0,2);

		INSERT 
		into Sales.SalesOrderHeader 
		(
			DueDate,
			OnlineOrderFlag,
			PurchaseOrderNumber,
			AccountNumber,
			CustomerID,
			SalesPersonID,
			TerritoryID,
			BillToAddressID,
			ShipToAddressID,
			ShipMethodID,
			CreditCardID,
			CreditCardApprovalCode
		)
		OUTPUT inserted.SalesOrderID into @OrderIDs
		SELECT TOP(@GeneratedRows)
			CAST(DATEADD(day, dbo.miGetRandomInt32(3,15), GETDATE()) as DATE),
			@isOnline,
			IIF(@isOnline = 0, 
				'PO' + CAST(dbo.miGetRandomInt32(100000,99999) as VARCHAR(6)) + CAST(dbo.miGetRandomInt32(100000,99999) as VARCHAR(6)),
				null),
			'10-40' + CAST(dbo.miGetRandomInt32(1,10)*10 as VARCHAR(2)) + CAST(dbo.miGetRandomInt32(100000,99999) as VARCHAR(6)),
			c.CustomerID,
			IIF(@isOnline = 0,
				(SELECT TOP 1 BusinessEntityID FROM Sales.SalesPerson ORDER BY dbo.miGetRandomInt32(0,1000)), 
				null),
			c.TerritoryID,
			addr.AddressID,
			addr.AddressID,
			(SELECT TOP 1 ShipMethodID FROM Purchasing.ShipMethod ORDER BY dbo.miGetRandomInt32(0,1000)),
			ccard.CreditCardID,
			CAST(dbo.miGetRandomInt32(100000,99999) as VARCHAR(6)) 
				+ 'Vi' 
				+ CAST(dbo.miGetRandomInt32(100000,99999) as VARCHAR(6))
		FROM Sales.Customer c
			cross apply (
				SELECT TOP 1 bea.AddressID
				FROM Person.BusinessEntityAddress bea
				WHERE bea.BusinessEntityID = c.PersonID
			) addr
			cross apply (
				SELECT TOP 1 cc.CreditCardID
				FROM Sales.PersonCreditCard pcc
					inner join Sales.CreditCard cc on pcc.CreditCardID = cc.CreditCardID
				WHERE pcc.BusinessEntityID = c.PersonID
			) ccard
		ORDER BY dbo.miGetRandomInt32(0,100000)

		SET @orderDetailsCount = dbo.miGetRandomInt32(1,6);

		WITH prods as 
		(
			SELECT TOP(@orderDetailsCount)
				ProductID,
				ListPrice
			FROM Production.Product p
			WHERE DiscontinuedDate is null
				and exists (SELECT 1 
							FROM Sales.SpecialOfferProduct sop 
							WHERE sop.ProductID = p.ProductID
						)
			ORDER BY dbo.miGetRandomInt32(0,1000)
		)
		INSERT
		into Sales.SalesOrderDetail
			(SalesOrderID, OrderQty, ProductID, UnitPrice, SpecialOfferID)
		SELECT
			oi.ID,
			dbo.miGetRandomInt32(1,4) OrderQty,
			ProductID,
			ListPrice,
			1
		FROM @OrderIDs oi, prods;

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