CREATE PROCEDURE [dbo].[miGenBusinessEntityAddresses]
	@GeneratedRows int = 5
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE @localTran BIT = 0;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

		-- create link between people without address and addresses without people
		-- it is possible that we create less rows than specified by @GeneratedRows
		with addr as
		(
			SELECT TOP(@GeneratedRows)
				ad.AddressID, ROW_NUMBER() OVER (ORDER BY dbo.miGetRandomInt32(0,1000)) rn
			FROM Person.Address ad
				left join Person.BusinessEntityAddress bea on ad.AddressID = bea.AddressID
			WHERE bea.AddressID is null
		),
		be as
		(
			SELECT TOP(@GeneratedRows)
				be.BusinessEntityID,
				p.PersonType,
				ROW_NUMBER() OVER (ORDER BY dbo.miGetRandomInt32(0,1000)) rn
			FROM Person.BusinessEntity be
				left join Person.BusinessEntityAddress bea on be.BusinessEntityID = bea.BusinessEntityID
				left join Person.Person p on be.BusinessEntityID = p.BusinessEntityID
			WHERE bea.BusinessEntityID is null
		)
		INSERT into Person.BusinessEntityAddress
			(AddressID, AddressTypeID, BusinessEntityID)
		SELECT
			addr.AddressID,
			 -- 2="Home" address for People, 3="Main office" for Stores/Vendors
			IIF(be.PersonType is not null, 2, 3),
			be.BusinessEntityID
		FROM be inner join addr on addr.rn = be.rn;

		SET @GeneratedRows = @GeneratedRows - @@ROWCOUNT

		IF @GeneratedRows > 0
		BEGIN
			-- if there are unlinked addresses add them to people as shipping address
			with addr as
			(
				SELECT TOP (@GeneratedRows)
					ad.AddressID, ROW_NUMBER() OVER (ORDER BY dbo.miGetRandomInt32(0,1000)) rn
				FROM Person.Address ad
					left join Person.BusinessEntityAddress bea on ad.AddressID = bea.AddressID
				WHERE bea.AddressID is null
			),
			per as
			(
				SELECT TOP (@GeneratedRows) 
					p.BusinessEntityID,
					ROW_NUMBER() OVER (ORDER BY dbo.miGetRandomInt32(0,1000)) rn
				FROM Person.Person p
					left join Person.BusinessEntityAddress bea on bea.BusinessEntityID = p.BusinessEntityID
															and bea.AddressTypeID = 5
				WHERE bea.BusinessEntityID is null
			)
			INSERT into Person.BusinessEntityAddress
				(AddressID, AddressTypeID, BusinessEntityID)
			SELECT
				addr.AddressID, 5, per.BusinessEntityID
			FROM per inner join addr on addr.rn = per.rn;

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