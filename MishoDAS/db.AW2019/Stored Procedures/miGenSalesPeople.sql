CREATE PROCEDURE [dbo].[miGenSalesPeople]
	@GeneratedRows int = 1
AS
BEGIN
	
	SET NOCOUNT ON;
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT,
		@Iter INT=0,
		@Check INT,
		@BEID INT;
	
	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		WHILE @Iter < @GeneratedRows
		BEGIN
			EXEC @Check = dbo.miAddRandomEmployee @EmployeeType='SP', @beID=@BEID OUTPUT

			IF @Check = -1
				RAISERROR('Abort Creating "Sales Person". Error while creating "Employee".', 16, 1);

			INSERT into Sales.SalesPerson(BusinessEntityID, TerritoryID, SalesQuota, Bonus)
			SELECT
				@BEID,
				st.TerritoryID,
				dbo.miGetRandomInt32(10,50) * 10000 as SalesQuota,
				dbo.miGetRandomInt32(1,50) * 100 as Bonus
			FROM Sales.SalesTerritory st
			WHERE st.TerritoryID = dbo.miGetRandomInt32(1,11);

			SET @Iter = @Iter + 1;
		END;

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