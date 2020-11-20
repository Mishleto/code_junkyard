CREATE PROCEDURE [dbo].[miGenEmpPayHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE @iter INT = 0;
	DECLARE @localTran BIT = 0;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

		INSERT into HumanResources.EmployeePayHistory
			(BusinessEntityID, Rate, PayFrequency, RateChangeDate)
		SELECT TOP(@GeneratedRows)
			BusinessEntityID,
			Rate * (1 + 0.01*DATEDIFF(month, RateChangeDate, GETDATE())) as Rate, 
			PayFrequency,
			CAST(GETDATE() AS DATE) as RateChangeDate
		FROM
		(
			SELECT 
				eph.*,
				ROW_NUMBER() OVER (PARTITION BY eph.BusinessEntityID ORDER BY RateChangeDate DESC) RN
			FROM HumanResources.EmployeePayHistory eph
		) empLastChange
		WHERE RN=1
		ORDER BY dbo.miGetRandomInt32(0,1000);
		

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;

		EXEC dbo.uspLogError;
		RETURN -1;
	END CATCH

RETURN 0
END;
