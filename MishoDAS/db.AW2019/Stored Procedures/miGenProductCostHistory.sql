CREATE PROCEDURE [dbo].[miGenProductCostHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE 
		@LocalTranFlag BIT = 0,
		@LogID INT;
	DECLARE @tmpProducts TABLE(
		ProductID INT,
		StandardCost MONEY,
		StartDate DATE
	);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into @tmpProducts
		SELECT TOP (@GeneratedRows)
			ProductID,
			StandardCost,
			StartDate
		FROM Production.ProductCostHistory
		WHERE EndDate is NULL and StartDate < DATEADD(day, -1, DATEADD(year, -1, GETDATE()))
		ORDER BY dbo.miGetRandomInt32(0,1000);

		UPDATE Production.ProductCostHistory
			set EndDate = DATEADD(day, -1, DATEADD(year, 1, StartDate)),
				ModifiedDate = GETDATE()
		WHERE ProductID in (SELECT t.ProductID FROM @tmpProducts t);

		INSERT into Production.ProductCostHistory
			(ProductID, StandardCost, StartDate)
		SELECT 
			t.ProductID,
			t.StandardCost * (1 +dbo.miGetRandomInt32(1,10)/100),
			DATEADD(year, 1, t.StartDate)
		FROM @tmpProducts t;

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