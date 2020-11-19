CREATE PROCEDURE [dbo].[miGenSalesPeople]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE @beID int;
	DECLARE @res int;
	DECLARE @iter int =  0;
	DECLARE @localTran BIT = 0;
	
	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

		WHILE @iter < @GeneratedRows
		BEGIN
			EXEC @res = dbo.miAddRandomEmployee @EmployeeType='SP', @beID=@beID OUTPUT

			IF @res = -1
				RAISERROR('Abort Creating "Sales Person". Error while creating "Employee".', 16, 1);

			INSERT into Sales.SalesPerson(BusinessEntityID, TerritoryID, SalesQuota, Bonus)
			SELECT
				@beID,
				st.TerritoryID,
				dbo.miGetRandomInt32(10,50) * 10000 as SalesQuota,
				dbo.miGetRandomInt32(1,50) * 100 as Bonus
			FROM Sales.SalesTerritory st
			WHERE st.TerritoryID = dbo.miGetRandomInt32(1,11);

			SET @iter = @iter + 1;
		END;

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
