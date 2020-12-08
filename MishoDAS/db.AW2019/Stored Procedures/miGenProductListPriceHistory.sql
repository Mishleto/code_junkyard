CREATE PROCEDURE [dbo].[miGenProductListPriceHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;
	DECLARE @tmpProducts TABLE(
		ProductID INT,
		ListPrice MONEY,
		StartDate DATE
	);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into @tmpProducts
		SELECT TOP (@GeneratedRows)
			ProductID,
			ListPrice,
			StartDate
		FROM Production.ProductListPriceHistory
		WHERE EndDate is NULL and StartDate < DATEADD(day, -1, DATEADD(year, -1, GETDATE()))
		ORDER BY dbo.miGetRandomInt32(0,1000);

		UPDATE Production.ProductListPriceHistory
			set EndDate = DATEADD(day, -1, DATEADD(year, 1, StartDate)),
				ModifiedDate = GETDATE()
		WHERE ProductID in (SELECT t.ProductID FROM @tmpProducts t);

		INSERT into Production.ProductListPriceHistory
			(ProductID, ListPrice, StartDate)
		SELECT 
			t.ProductID,
			t.ListPrice * (1 +dbo.miGetRandomInt32(1,10)/100),
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