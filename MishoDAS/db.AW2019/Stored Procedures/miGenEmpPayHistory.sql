CREATE PROCEDURE [dbo].[miGenEmpPayHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

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