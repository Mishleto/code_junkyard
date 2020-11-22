CREATE PROCEDURE [dbo].[miGenAddresses]
	@GeneratedRows int = 10
AS
BEGIN

	DECLARE @localTran BIT = 0;
	DECLARE @iter int = 0;

	DECLARE @StateProvinceID INT;
	DECLARE @PostalCode VARCHAR(5);
	DECLARE @City VARCHAR(50);
	DECLARE @RandGeography geography;
	
	BEGIN TRY

		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

		-- get random StateProvinceID - All addresses will be added there
		SELECT TOP 1
			@StateProvinceID = StateProvinceID,
			@PostalCode = CAST(dbo.miGetRandomInt32(1000,99999) as VARCHAR(5)),
			@City = dbo.miCapitalizeString(dbo.miGetRandomAplhaString(10,1))
		FROM Person.StateProvince sp
		WHERE EXISTS (
				SELECT 1 
				FROM Person.Address a
				WHERE a.StateProvinceID = sp.StateProvinceID
			)
		ORDER BY dbo.miGetRandomInt32(0, 10000);

		-- Get Random address from this province. I will add random values to its latitude and longtitude
		SELECT TOP 1
			@RandGeography = SpatialLocation
		FROM Person.Address a
		WHERE a.StateProvinceID = @StateProvinceID
		ORDER BY dbo.miGetRandomInt32(0,10000);

		-- Insert random Addresses near the selected location
		WHILE @iter < @GeneratedRows
		BEGIN
			
			INSERT into Person.Address
				(AddressLine1, City, PostalCode, StateProvinceID, SpatialLocation)
			VALUES (
				CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4)) 
					+ ' ' + dbo.miCapitalizeString(dbo.miGetRandomAplhaString(30)),
				@City,
				@PostalCode,
				@StateProvinceID,
				geography::Point(
					@RandGeography.Lat + dbo.miGetRandomInt32(-1000,1000)/power(10.0,5),
					@RandGeography.Long + dbo.miGetRandomInt32(-1000,1000)/power(10.0,5), 
					@RandGeography.STSrid)
			);

			SET @iter = @iter + 1;
		END;

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;
		
		EXECUTE [dbo].[uspLogError];
		RETURN -1
	END CATCH

	RETURN 0
END;