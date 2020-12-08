CREATE PROCEDURE [dbo].[miGenEmpDepartmentHistory]
	@GeneratedRows int = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;
	DECLARE @tmpEDH TABLE(
		BusinessEntityID INT,
		DepartmentID INT,
		ShiftID INT
	);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into @tmpEDH
		SELECT TOP (@GeneratedRows)
			BusinessEntityID,
			DepartmentID,
			ShiftID
		FROM HumanResources.EmployeeDepartmentHistory
		WHERE EndDate is NULL
		ORDER BY dbo.miGetRandomInt32(0,1000);

		UPDATE HumanResources.EmployeeDepartmentHistory
			set EndDate = DATEADD(day, -1, CAST(GETDATE() AS DATE)),
				ModifiedDate = GETDATE()
		WHERE BusinessEntityID in (SELECT t.BusinessEntityID FROM @tmpEDH t);

		INSERT into HumanResources.EmployeeDepartmentHistory
			(BusinessEntityID, DepartmentID, ShiftID, StartDate)
		SELECT 
			t.BusinessEntityID,
			t.DepartmentID,
			ns.ShiftID,
			CAST(GETDATE() as DATE) as StartDate
		FROM @tmpEDH t
			cross apply (
				SELECT TOP 1 s.ShiftID 
				FROM HumanResources.Shift s
				WHERE s.ShiftID <> t.ShiftID
				ORDER BY dbo.miGetRandomInt32(0,100)
			) ns;

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