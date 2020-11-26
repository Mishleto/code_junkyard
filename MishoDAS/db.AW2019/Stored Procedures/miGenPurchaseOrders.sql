CREATE PROCEDURE [dbo].[miGenPurchaseOrders]
	@GeneratedRows int = 5
AS
BEGIN

	DECLARE @localTran BIT = 0;
	DECLARE @iter INT = 0;
	DECLARE @EmployeeID INT;
	DECLARE @VendorID INT;
	DECLARE @ShipMethodID INT;
	DECLARE @PurchaseOrderID INT;
	DECLARE @DetailsCount INT;

	BEGIN TRY

		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;
		
		WHILE @iter < @GeneratedRows
		BEGIN
			SET	@EmployeeID = (SELECT TOP 1 BusinessEntityID 
								FROM HumanResources.Employee 
								ORDER BY dbo.miGetRandomInt32(0,1000));
			SET	@VendorID = (SELECT TOP 1 BusinessEntityID 
								FROM HumanResources.Employee 
								ORDER BY dbo.miGetRandomInt32(0,1000));
			SET	@ShipMethodID = (SELECT TOP 1 ShipMethodID 
									FROM Purchasing.ShipMethod 
									ORDER BY dbo.miGetRandomInt32(0,1000));

			INSERT
			into Purchasing.PurchaseOrderHeader 
				(EmployeeID, VendorID, ShipMethodID, OrderDate, ShipDate)
			VALUES (
				@EmployeeID,
				@VendorID,
				@ShipMethodID,
				CAST(GETDATE() as DATE),
				CAST(DATEADD(day, dbo.miGetRandomInt32(10,30), GETDATE()) as DATE)
			);
			
			SET @PurchaseOrderID = SCOPE_IDENTITY();
			SET @DetailsCount = dbo.miGetRandomInt32(1,6);

			INSERT 
			into Purchasing.PurchaseOrderDetail
				(PurchaseOrderID, DueDate, OrderQty, ProductID, UnitPrice, ReceivedQty, RejectedQty)
			SELECT TOP (@DetailsCount)
				@PurchaseOrderID,
				CAST(DATEADD(day, dbo.miGetRandomInt32(10,28), GETDATE()) as DATE) as DueDate,
				dbo.miGetRandomInt32(4,20) * 5 as OrderQty,
				p.ProductID,
				p.ListPrice,
				0 as ReceivedQty,
				0 as RejectedQty
			FROM Production.Product p
			WHERE p.DiscontinuedDate is null
			ORDER BY dbo.miGetRandomInt32(0,1000);


			SET @iter = @iter + 1;
		END;

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