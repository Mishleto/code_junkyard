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
	
	SET NOCOUNT ON;
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT, 
		@Iter int = 0,
		@BEID int,
		@BEOwner int,
		@Check INT;

	BEGIN TRY

		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		WHILE @Iter < @GeneratedRows
		BEGIN
			
			-- insert BusinessEntity record for the Store record
			INSERT 
			into Person.BusinessEntity(rowguid) 
			VALUES (NEWID())

			SET @BEID = SCOPE_IDENTITY();

			INSERT into Sales.Store(BusinessEntityID,Name,SalesPersonID)
			SELECT TOP 1
				@BEID,
				dbo.miCapitalizeString(dbo.miGetRandomAlphaString(20,0)),
				sp.BusinessEntityID
			FROM Sales.SalesPerson sp
			ORDER BY dbo.miGetRandomInt32(0,100);

			-- insert Person record that will play the role of Store Owner
			EXEC @Check = dbo.miAddRandomPerson @PersonType = 'SC', @beID=@BEOwner OUTPUT;
			IF @Check = -1
				RAISERROR('Abort inserting "Store" because Store Owner was not created.', 16,1);

			INSERT into Person.BusinessEntityContact(BusinessEntityID, ContactTypeID, PersonID)
			VALUES (@BEID, 11, @BEOwner);
		
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