CREATE PROCEDURE [dbo].[miGenWorkOrders]
	@GeneratedRows int = 1
AS
BEGIN
	
	SET NOCOUNT ON;
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;
	DECLARE @woTbl TABLE (
			WorkOrderID INT,
			ProductID INT,
			OrderQty INT,
			ScheduledStartDate DATE,
			ScheduledEndDate DATE
		);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		INSERT into Production.WorkOrder(ProductID, OrderQty, ScrappedQty, StartDate, DueDate)
		OUTPUT inserted.WorkOrderID, inserted.ProductID, inserted.OrderQty, inserted.StartDate, inserted.DueDate 
			into @woTbl
		SELECT TOP(@GeneratedRows)
			p.ProductID,
			dbo.miGetRandomInt32(10,100) * 10 as OrderQty,
			0 as ScrappedQty,
			DATEADD(day, dbo.miGetRandomInt32(1,7), GETDATE()),
			DATEADD(day, dbo.miGetRandomInt32(10,30), GETDATE())
		FROM Production.Product p
			left join  Production.WorkOrder wo on p.ProductID = wo.ProductID
											and wo.EndDate is null
		WHERE wo.ProductID is null
		ORDER BY dbo.miGetRandomInt32(0,1000);

		INSERT 
		into Production.WorkOrderRouting 
		(
			WorkOrderID,
			ProductID,
			OperationSequence,
			LocationID,
			ScheduledStartDate,
			ScheduledEndDate,
			PlannedCost
		)
		SELECT 
			wot.WorkOrderID,
			wot.ProductID,
			1,
			6,
			wot.ScheduledStartDate,
			wot.ScheduledEndDate,
			wot.OrderQty * p.StandardCost + 10
		FROM @woTbl wot
			inner join Production.Product p on wot.ProductID = p.ProductID;
		
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