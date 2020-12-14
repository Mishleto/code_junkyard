CREATE PROCEDURE [dbo].[miGenAddresses]
	@GeneratedRows int = 10
AS
BEGIN
	
	SET NOCOUNT ON;

	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT, 
		@Iter int = 0,
		@StateProvinceID INT,
		@PostalCode VARCHAR(5),
		@City VARCHAR(50),
		@RandGeography geography;

	BEGIN TRY

		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		-- get random StateProvinceID - All addresses will be added there
		SELECT TOP 1
			@StateProvinceID = StateProvinceID,
			@PostalCode = CAST(dbo.miGetRandomInt32(1000,99999) as VARCHAR(5)),
			@City = dbo.miCapitalizeString(dbo.miGetRandomAlphaString(10,1))
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
		WHILE @Iter < @GeneratedRows
		BEGIN
			
			INSERT into Person.Address
				(AddressLine1, City, PostalCode, StateProvinceID, SpatialLocation)
			VALUES (
				CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4)) 
					+ ' ' + dbo.miCapitalizeString(dbo.miGetRandomAlphaString(30,0)),
				@City,
				@PostalCode,
				@StateProvinceID,
				geography::Point(
					@RandGeography.Lat + dbo.miGetRandomInt32(-1000,1000)/power(10.0,5),
					@RandGeography.Long + dbo.miGetRandomInt32(-1000,1000)/power(10.0,5), 
					@RandGeography.STSrid)
			);

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