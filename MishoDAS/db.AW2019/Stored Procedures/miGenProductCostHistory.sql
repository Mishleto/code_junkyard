CREATE PROCEDURE [dbo].[miGenProductCostHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE @localTran BIT = 0;
	DECLARE @tmpProducts TABLE(
		ProductID INT,
		StandardCost MONEY,
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