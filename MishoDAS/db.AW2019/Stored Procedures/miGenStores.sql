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
	DECLARE @beOwner int;
	DECLARE @check INT;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1
		END;

		WHILE @iter < @GeneratedRows
		BEGIN
			
			-- insert BusinessEntity record for the Store record
			INSERT 
			into Person.BusinessEntity(rowguid) 
			VALUES (NEWID())

			SET @beID = SCOPE_IDENTITY();

			INSERT into Sales.Store(BusinessEntityID,Name,SalesPersonID,rowguid)
			SELECT TOP 1
				@beID,
				dbo.miCapitalizeString(dbo.miGetRandomAlphaString(20,0)),
				sp.BusinessEntityID,
				NEWID()
			FROM Sales.SalesPerson sp
			ORDER BY dbo.miGetRandomInt32(0,100);

			-- insert Person record that will play the role of Store Owner
			EXEC @check = dbo.miAddRandomPerson @PersonType = 'SC', @beID=@beOwner;
			IF @check = -1
				RAISERROR('Abort inserting "Store" because Store Owner was not created.', 16,1);

			INSERT into Person.BusinessEntityContact(BusinessEntityID, ContactTypeID,PersonID)
			VALUES (@beID, 11, @beOwner);
		
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
