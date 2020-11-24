CREATE PROCEDURE [dbo].[miGenProductListPriceHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE @localTran BIT = 0;
	DECLARE @tmpProducts TABLE(
		ProductID INT,
		ListPrice MONEY,
		StartDate DATE
	);

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

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
