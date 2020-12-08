CREATE PROCEDURE [dbo].[miGenCustomers]
	@GeneratedRows int = 10
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		-- Registrer rows from Person.Person with type "Individual Customer"
		with per_wc as 
		(
			SELECT TOP (@GeneratedRows)
				per.BusinessEntityID
			FROM Person.Person per
				left join Sales.Customer c on per.BusinessEntityID = c.PersonID
			WHERE per.PersonType = 'IN'
				and c.PersonID is null
		)
		INSERT into Sales.Customer (PersonID, TerritoryID)
		SELECT per_wc.BusinessEntityID, t.TerritoryID
		FROM per_wc cross apply (
				SELECT TOP 1 sp.TerritoryID
				FROM Person.BusinessEntityAddress bea
					inner join Person.Address ad on bea.AddressID = ad.AddressID
					inner join Person.StateProvince sp on ad.StateProvinceID = sp.StateProvinceID
				WHERE bea.BusinessEntityID = per_wc.BusinessEntityID
				-- set address type priority.
				ORDER BY 
					CASE
						WHEN bea.AddressTypeID = 2 THEN 100 -- Home
						WHEN bea.AddressTypeID = 4 THEN 200 -- Primary
						WHEN bea.AddressTypeID = 5 THEN 300 -- Shipping
						WHEN bea.AddressTypeID = 1 THEN 400 -- Billing
						WHEN bea.AddressTypeID = 3 THEN 500 -- Main Office
						ELSE 1000
					END
			) t;
		
		SET @GeneratedRows = @GeneratedRows - @@ROWCOUNT;
		
		-- Registrer Stores
		IF @GeneratedRows > 0
		BEGIN
			with s_wc as 
			(
				SELECT TOP (@GeneratedRows)
					s.BusinessEntityID
				FROM Sales.Store s
					left join Sales.Customer c on s.BusinessEntityID = c.StoreID
				WHERE c.StoreID is null
			)
			INSERT into Sales.Customer (StoreID, TerritoryID)
			SELECT s_wc.BusinessEntityID, t.TerritoryID
			FROM s_wc cross apply (
					SELECT TOP 1 sp.TerritoryID
					FROM Person.BusinessEntityAddress bea
						inner join Person.Address ad on bea.AddressID = ad.AddressID
						inner join Person.StateProvince sp on ad.StateProvinceID = sp.StateProvinceID
					WHERE bea.BusinessEntityID = s_wc.BusinessEntityID
					-- set address type priority.
					ORDER BY 
						CASE
							WHEN bea.AddressTypeID = 3 THEN 100 -- Main Office
							WHEN bea.AddressTypeID = 4 THEN 200 -- Primary
							WHEN bea.AddressTypeID = 1 THEN 300 -- Billing
							WHEN bea.AddressTypeID = 5 THEN 400 -- Shipping
							WHEN bea.AddressTypeID = 2 THEN 500 -- Home
							ELSE 1000
						END
				) t;
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