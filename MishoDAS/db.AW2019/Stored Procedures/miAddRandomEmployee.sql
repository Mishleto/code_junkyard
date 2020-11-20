CREATE PROCEDURE [dbo].[miAddRandomEmployee]
	@EmployeeType CHAR(2) = 'EM',
	@beID INT OUTPUT
AS
BEGIN
	DECLARE @localTran BIT = 0;
	DECLARE @res INT;

	DECLARE @ManagerNode hierarchyid;
	DECLARE @RightmostChild hierarchyid;
	DECLARE @JobTitle NVARCHAR(50);
	DECLARE @DepartmentID INT;
	DECLARE @ShiftID INT;
	DECLARE @Rate MONEY;
	DECLARE @PayFrequency TINYINT;
	
	BEGIN TRY
		
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran =1;
		END;

		EXEC @res=dbo.miAddRandomPerson @PersonType=@EmployeeType, @beID=@beID OUTPUT

		IF @res is null or @res = -1
			RAISERROR ('Abort inserting "Employee" because "Person" was not created.', 16,1);  

		-- Get random employee from a random level (0,1 or 2) to be manager of the new employee
		-- Get also the department, shift and half of the Manager's salary. They will be the values for the new employee
		SELECT TOP 1 
			@ManagerNode = OrganizationNode,
			@DepartmentID = edh.DepartmentID,
			@ShiftID = edh.ShiftID,
			@Rate = ph.Rate / 2,
			@PayFrequency = ph.PayFrequency
		FROM HumanResources.Employee e
			left join HumanResources.EmployeeDepartmentHistory edh on edh.BusinessEntityID = e.BusinessEntityID
																and edh.EndDate is null
			outer apply (
				SELECT TOP 1 
					eph.Rate, eph.PayFrequency
				FROM HumanResources.EmployeePayHistory eph
				WHERE eph.BusinessEntityID = e.BusinessEntityID
				ORDER BY eph.RateChangeDate desc
			) ph
		WHERE OrganizationLevel = dbo.miGetRandomInt32(0,3)
		ORDER BY dbo.miGetRandomInt32(0,100);

		-- Get the biggest descendant ot the manager that we selected at random
		SELECT TOP 1
			@RightmostChild = OrganizationNode,
			@JobTitle = JobTitle
		FROM HumanResources.Employee e
		WHERE OrganizationNode.GetAncestor(1) = @ManagerNode
		ORDER BY OrganizationNode desc
		OPTION (FORCE ORDER);

		
		INSERT
		into HumanResources.Employee
		(
			BusinessEntityID, 
			NationalIDNumber,
			LoginID,
			OrganizationNode,
			JobTitle,
			BirthDate,
			MaritalStatus,
			Gender,
			HireDate
		)
		SELECT
			@beID as BusinessEntityID,
			CAST(dbo.miGetRandomInt32(10000,99999) as VARCHAR(5)) 
				+ CAST(dbo.miGetRandomInt32(10000,99999) as VARCHAR(5)) as NationalIDNumber,
			'adventure-works\'+ p.FirstName + '0' as LoginID,
			@ManagerNode.GetDescendant(@RightmostChild, NULL) as OrganizationNode,
			IIF(@JobTitle is NULL, 'P.L.E.A.S.E.', @JobTitle) as JobTitle,
			datefromparts(dbo.miGetRandomInt32(1960,2001), dbo.miGetRandomInt32(1,13), dbo.miGetRandomInt32(1,29)) as BirthDate,
			IIF(dbo.miGetRandomInt32(0,2) = 0, 'S', 'M') as MaritalStatus,
			IIF(dbo.miGetRandomInt32(0,2) = 0, 'F', 'M') as Gender,
			GETDATE() as HireDate
		FROM Person.Person p
		WHERE p.BusinessEntityID = @beID

		INSERT into HumanResources.EmployeeDepartmentHistory
			(BusinessEntityID, DepartmentID, ShiftID, StartDate)
		VALUES(@beID, @DepartmentID, @ShiftID, CAST(GETDATE() as DATE));

		INSERT into HumanResources.EmployeePayHistory
			(BusinessEntityID, Rate, PayFrequency, RateChangeDate)
		VALUES(@beID, @Rate, @PayFrequency, CAST(GETDATE() as DATE));

		
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
