﻿CREATE PROCEDURE [dbo].[miGenVendors]
/*
	A Vendor must have an address but I will not add addresses here for two reasons:
		1. It's easier :). 
		2. I will generate random addresses that later will be associated with Vendors without Address. 
			This will allow me to tackle the challenge of "late-arriving data" in the DWH
*/
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE @localTran BIT = 0;
	DECLARE @iter INT = 0;
	DECLARE @beID INT;
	DECLARE @beManager INT;
	DECLARE @check INT;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END

		WHILE @iter < @GeneratedRows 
		BEGIN
		
			INSERT into Person.BusinessEntity(rowguid)
			VALUES (NEWID());

			SET @beID = SCOPE_IDENTITY();

			with vendor_info(preffix) as
			(
				SELECT upper(dbo.miGetRandomAlphaString(6,1))
			)
			INSERT 
			into Purchasing.Vendor(BusinessEntityID, AccountNumber, Name, CreditRating, PreferredVendorStatus, ActiveFlag)
			SELECT 
				@beID,
				preffix + '0001' as AccountNumber,
				LEFT(preffix,1) + LOWER(SUBSTRING(preffix,2, len(preffix)-1)) + ' Cycling' as Name,
				dbo.miGetRandomInt32(1,6) as CreditRating,
				dbo.miGetRandomInt32(0,2) as PrefferdVendorStatus,
				1 as ActiveFlag
			FROM vendor_info;

			-- insert Person record that will play the role of Store Owner
			EXEC @check = dbo.miAddRandomPerson @PersonType = 'VC', @beID=@beManager;
			IF @check = -1
				RAISERROR('Abort inserting "Vendor" because Vendor Manager was not created.', 16,1);

			INSERT into Person.BusinessEntityContact(BusinessEntityID, ContactTypeID,PersonID)
			VALUES (@beID, 11, @beManager);

			SET @iter = @iter + 1;
		END;

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;

		EXEC dbo.uspLogError;
		RETURN -1
	END CATCH

	RETURN 0
END;
