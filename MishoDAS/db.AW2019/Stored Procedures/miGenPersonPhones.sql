CREATE PROCEDURE [dbo].[miGenPersonPhones]
	@GeneratedRows int = 5
AS
BEGIN
	
	SET NOCOUNT ON;
	
	IF @GeneratedRows < 1
		RETURN;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		WITH per_wp as
		(
			SELECT TOP (@GeneratedRows)
				per.BusinessEntityID
			FROM Person.Person per
				left join Person.PersonPhone pp on per.BusinessEntityID = pp.BusinessEntityID
			WHERE pp.BusinessEntityID is null
			ORDER BY dbo.miGetRandomInt32(1,1000)
		)
		INSERT into Person.PersonPhone
			(BusinessEntityID, PhoneNumberTypeID, PhoneNumber)
		SELECT
			per_wp.BusinessEntityID,
			1, -- Cell Phone
			CAST(dbo.miGetRandomInt32(500,999) as VARCHAR(3))
				+ '-' + CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4))
				+ '-' + CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4))
		FROM per_wp;
		
		SET @GeneratedRows = @GeneratedRows - @@ROWCOUNT

		IF @GeneratedRows > 0
		BEGIN
			WITH per_wp as
			(
				SELECT TOP (@GeneratedRows)
					per.BusinessEntityID,
					max(PhoneNumberTypeID) as PhoneNumberTypeID
				FROM Person.Person per
					inner join Person.PersonPhone pp on per.BusinessEntityID = pp.BusinessEntityID
				GROUP BY per.BusinessEntityID
				HAVING count(*) = 1
				ORDER BY dbo.miGetRandomInt32(1,1000)
			)
			INSERT into Person.PersonPhone
				(BusinessEntityID, PhoneNumberTypeID, PhoneNumber)
			SELECT
				per_wp.BusinessEntityID,
				IIF(PhoneNumberTypeID=1, 3, 1), -- Add "Cell" type if person already has "Work" and vice-versa 
				CAST(dbo.miGetRandomInt32(500,999) as VARCHAR(3))
					+ '-' + CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4))
					+ '-' + CAST(dbo.miGetRandomInt32(1000,9999) as VARCHAR(4))
			FROM per_wp;
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