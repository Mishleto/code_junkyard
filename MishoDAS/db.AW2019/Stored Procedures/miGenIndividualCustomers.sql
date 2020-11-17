CREATE PROCEDURE [dbo].[miGenIndividualCustomers]
	@GeneratedRows int = 10
AS
BEGIN
	
	DECLARE @iter int = 0;
	DECLARE @beID int;

	WHILE @iter < @GeneratedRows
	BEGIN
		
		INSERT 
		into Person.BusinessEntity(rowguid) 
		VALUES (NEWID());
		
		SET @beID = SCOPE_IDENTITY();

		INSERT
		into Person.Person(BusinessEntityID, PersonType, Title, FirstName, MiddleName, LastName, EmailPromotion)
		SELECT
			@beID,
			'IN' as PersonType,
			CASE
				WHEN rit.RndVal % 15 = 0 THEN 'Ms'
				WHEN (rit.RndVal+1) % 15 = 0 THEN 'Mrs'
				WHEN (rit.RndVal+2) % 15 = 0 THEN 'Mr'
				ELSE NULL
			END as Title,
			dbo.miCapitalizeString(
				dbo.miGetRandomAplhaString(15,0)) as FirstName,
			dbo.miCapitalizeString(
				dbo.miGetRandomAplhaString(1,0)) as MiddleName,
			dbo.miCapitalizeString(
				dbo.miGetRandomAplhaString(15,0)) as LastName,
			CASE
				WHEN rit.RndVal % 4 = 0 THEN 2
				WHEN (rit.RndVal+1) % 4 = 0 THEN 1
				ELSE 0
			END as EmailPromotion
		FROM miGetRandomIntTable(1, 0, 1000) rit
		OPTION(FORCE ORDER);

		SET @iter = @iter +1;
	END;

END;