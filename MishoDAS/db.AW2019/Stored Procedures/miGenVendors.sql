CREATE PROCEDURE [dbo].[miGenVendors]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE @localTran BIT = 0;
	DECLARE @iter INT = 0;
	DECLARE @beID INT;

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
				SELECT upper(dbo.miGetRandomAplhaString(6,1))
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
