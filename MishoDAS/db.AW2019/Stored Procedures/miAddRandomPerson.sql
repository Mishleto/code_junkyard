CREATE PROCEDURE [dbo].[miAddRandomPerson]
	@PersonType CHAR(2)='IN',
	@beID INT OUTPUT
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @localTran BIT = 0;

	BEGIN TRY

		IF @@TRANCOUNT=0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran=1;
		END;

		INSERT 
		into Person.BusinessEntity(rowguid) 
		VALUES (NEWID());

		SET @beID = SCOPE_IDENTITY();

		INSERT
		into Person.Person(BusinessEntityID, PersonType, Title, FirstName, MiddleName, LastName, EmailPromotion)
		SELECT
			@beID,
			@PersonType as PersonType,
			CASE
				WHEN rit.RndVal % 15 = 0 THEN 'Ms'
				WHEN (rit.RndVal+1) % 15 = 0 THEN 'Mrs'
				WHEN (rit.RndVal+2) % 15 = 0 THEN 'Mr'
				ELSE NULL
			END as Title,
			dbo.miCapitalizeString(
				dbo.miGetRandomAlphaString(15,0)) as FirstName,
			dbo.miCapitalizeString(
				dbo.miGetRandomAlphaString(1,0)) as MiddleName,
			dbo.miCapitalizeString(
				dbo.miGetRandomAlphaString(15,0)) as LastName,
			CASE
				WHEN rit.RndVal % 4 = 0 THEN 2
				WHEN (rit.RndVal+1) % 4 = 0 THEN 1
				ELSE 0
			END as EmailPromotion
		FROM miGetRandomIntTable(1, 0, 1000) rit
		OPTION(FORCE ORDER);

		IF @localTran = 1
			COMMIT;

	END TRY

	BEGIN CATCH
		IF @localTran=1
			ROLLBACK;

		EXECUTE [dbo].[uspLogError];
		RETURN -1
	END CATCH

	RETURN 0
END;
