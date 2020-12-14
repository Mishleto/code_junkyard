CREATE PROCEDURE [dbo].[miGenVendors]
/*
	A Vendor must have an address but I will not add addresses here for two reasons:
		1. It's easier :). 
		2. I will generate random addresses that later will be associated with Vendors without Address. 
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
		@Iter INT = 0,
		@BEID INT,
		@BEManager INT,
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
		
			INSERT into Person.BusinessEntity(rowguid)
			VALUES (NEWID());

			SET @BEID = SCOPE_IDENTITY();

			with vendor_info(preffix) as
			(
				SELECT upper(dbo.miGetRandomAlphaString(6,1))
			)
			INSERT 
			into Purchasing.Vendor(BusinessEntityID, AccountNumber, Name, CreditRating, PreferredVendorStatus, ActiveFlag)
			SELECT 
				@BEID,
				preffix + '0001' as AccountNumber,
				LEFT(preffix,1) + LOWER(SUBSTRING(preffix,2, len(preffix)-1)) + ' Cycling' as Name,
				dbo.miGetRandomInt32(1,6) as CreditRating,
				dbo.miGetRandomInt32(0,2) as PrefferdVendorStatus,
				1 as ActiveFlag
			FROM vendor_info;

			-- insert Person record that will play the role of Vendor's Manager
			EXEC @Check = dbo.miAddRandomPerson @PersonType = 'VC', @beID=@BEManager OUTPUT;
			IF @Check = -1
				RAISERROR('Abort inserting "Vendor" because Vendor Manager was not created.', 16,1);

			INSERT into Person.BusinessEntityContact(BusinessEntityID, ContactTypeID,PersonID)
			VALUES (@beID, 11, @BEManager);

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