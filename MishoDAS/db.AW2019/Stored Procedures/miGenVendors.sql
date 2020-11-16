CREATE PROCEDURE [dbo].[miGenVendors]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE @iter INT = 0;
	DECLARE @beID INT;

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

END;
