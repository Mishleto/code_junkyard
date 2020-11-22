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

		WITH be_we as
		(
			SELECT TOP (@GeneratedRows)
				ea.BusinessEntityID
			FROM Person.BusinessEntity be
				left join Person.EmailAddress ea on be.BusinessEntityID = ea.BusinessEntityID
			WHERE ea.BusinessEntityID is null
			ORDER BY dbo.miGetRandomInt32(1,1000)
		)
		INSERT into Person.EmailAddress
			(BusinessEntityID, EmailAddress)
		SELECT
			be_we.BusinessEntityID,
			dbo.miGetRandomAlphaString(6,1) 
				+ '_' + dbo.miGetRandomAlphaNumString(8,0)
				+ '@mishomail.com'
		FROM be_we
		

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