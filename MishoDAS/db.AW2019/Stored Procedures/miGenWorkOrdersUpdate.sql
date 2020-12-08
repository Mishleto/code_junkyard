CREATE PROCEDURE [dbo].[miGenWorkOrdersUpdate]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;
	DECLARE @woTbl TABLE (
		WorkOrderID INT,
		ProductID INT,
		ScrappedPct INT,
		ScrapReasonID INT,
		ActualCostPct FLOAT
	);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into @woTbl
		SELECT TOP(@GeneratedRows) 
			WorkOrderID,
			ProductID,
			dbo.miGetRandomInt32(-10,11) as ScrappedPct,
			(SELECT TOP 1 ScrapReasonID
				FROM Production.ScrapReason
				ORDER BY dbo.miGetRandomInt32(0,1000)) as ScrapReasonID,
			1.0 + dbo.miGetRandomInt32(-10,11)/100.0
		FROM Production.WorkOrder 
		WHERE EndDate is null 
			and DueDate > DATEADD(day, -3, GETDATE())
		ORDER BY dbo.miGetRandomInt32(0,1000)

		UPDATE trg
			SET trg.EndDate=CAST(GETDATE() as DATE),
				trg.ScrappedQty = IIF(src.ScrappedPct > 0, floor(trg.OrderQty * (1.0 - src.ScrappedPct/100.0)), 0),
				trg.ScrapReasonID = IIF(src.ScrappedPct > 0, src.ScrapReasonID, NULL),
				trg.ModifiedDate = GETDATE()
		FROM Production.WorkOrder trg
			inner join @woTbl src on trg.WorkOrderID = src.WorkOrderID;

		UPDATE trg
			SET trg.ActualStartDate = DATEADD(day, dbo.miGetRandomInt(-1,5), trg.ActualStartDate),
				trg.ActualEndDate = CAST(GETDATE() as DATE),
				trg.ActualResourceHrs = floor(trg.ActualResourceHrs * src.ActualCostPct),
				trg.ActualCost = floor(trg.ActualCost * src.ActualCostPct),
				trg.ModifiedDate = GETDATE()
		FROM Production.WorkOrderRouting trg
			inner join @woTbl src on trg.WorkOrderID = src.WorkOrderID
								and trg.ProductID = src.ProductID;
			
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