CREATE PROCEDURE [dbo].[miGenStores]
/*
	A store must have an address but I will not add addresses here for two reasons:
		1. It's easier :). 
		2. I will generate random addresses that later will be associated with Stores without Address. 
			This will allow me to tackle the challenge of "late-arriving data" in the DWH
*/
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE @localTran BIT = 0;
	DECLARE @iter int = 0;
	DECLARE @beID int;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1
		END;

		WHILE @iter < @GeneratedRows
		BEGIN
		
			INSERT 
			into Person.BusinessEntity(rowguid) 
			VALUES (NEWID())

			SET @beID = SCOPE_IDENTITY();

			INSERT into Sales.Store(BusinessEntityID,Name,SalesPersonID,rowguid)
			SELECT TOP 1
				@beID,
				dbo.miCapitalizeString(dbo.miGetRandomAplhaString(20,0)),
				sp.BusinessEntityID,
				NEWID()
			FROM Sales.SalesPerson sp
			ORDER BY dbo.miGetRandomInt32(0,100);
		
			SET @iter = @iter + 1;
		END;

		IF @localTran=1
			COMMIT;

	END TRY

	BEGIN CATCH
		IF @localTran=1
			ROLLBACK;

		EXEC dbo.uspLogError;
		RETURN -1
	END CATCH

	RETURN 0
END;
