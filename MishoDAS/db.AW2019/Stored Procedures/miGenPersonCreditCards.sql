CREATE PROCEDURE [dbo].[miGenPersonCreditCards]
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
		END

		with cc as
		(
			SELECT 
				cc.CreditCardID, ROW_NUMBER() OVER (ORDER BY dbo.miGetRandomInt32(0,1000)) rn
			FROM Sales.CreditCard cc
				left join Sales.PersonCreditCard pcc on cc.CreditCardID = pcc.CreditCardID
			WHERE pcc.CreditCardID is null
		),
		per as
		(
			SELECT 
				per.BusinessEntityID, ROW_NUMBER() OVER (ORDER BY dbo.miGetRandomInt32(0,1000)) rn
			FROM Person.Person per
				left join Sales.PersonCreditCard pcc on per.BusinessEntityID = pcc.BusinessEntityID
			WHERE per.PersonType in ('SC', 'IM')
				and pcc.BusinessEntityID is null
		)
		INSERT into Sales.PersonCreditCard
			(BusinessEntityID, CreditCardID)
		SELECT 
			per.BusinessEntityID, cc.CreditCardID
		FROM per inner join cc on per.rn = cc.rn
		WHERE per.RN <= @GeneratedRows

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