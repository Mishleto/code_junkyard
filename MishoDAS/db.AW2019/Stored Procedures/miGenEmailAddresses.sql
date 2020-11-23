CREATE PROCEDURE [dbo].[miGenEmailAddresses]
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

		WITH per_we as
		(
			SELECT TOP (@GeneratedRows)
				per.BusinessEntityID
			FROM Person.Person per
				left join Person.EmailAddress ea on per.BusinessEntityID = ea.BusinessEntityID
			WHERE ea.BusinessEntityID is null
			ORDER BY dbo.miGetRandomInt32(1,1000)
		)
		INSERT into Person.EmailAddress
			(BusinessEntityID, EmailAddress)
		SELECT
			per_we.BusinessEntityID,
			dbo.miGetRandomAlphaString(6,1) 
				+ '_' + dbo.miGetRandomAlphaNumString(8,0)
				+ '@mishomail.com'
		FROM per_we;

		SET @GeneratedRows = @GeneratedRows - @@ROWCOUNT

		IF @GeneratedRows > 0
		BEGIN
			WITH per_we as
			(
				SELECT TOP (@GeneratedRows)
					COUNT(*) as mails_per_person,
					per.BusinessEntityID
				FROM Person.Person per
					inner join Person.EmailAddress ea on per.BusinessEntityID = ea.BusinessEntityID
				GROUP BY per.BusinessEntityID
				ORDER BY 1, dbo.miGetRandomInt32(1,1000)
			)
			INSERT into Person.EmailAddress
				(BusinessEntityID, EmailAddress)
			SELECT
				per_we.BusinessEntityID,
				dbo.miGetRandomAlphaString(6,1) 
					+ '_' + dbo.miGetRandomAlphaNumString(8,0)
					+ '@bozamail.com'
			FROM per_we;
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