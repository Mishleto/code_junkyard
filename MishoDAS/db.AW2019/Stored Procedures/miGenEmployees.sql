CREATE PROCEDURE [dbo].[miGenEmployees]
	@GeneratedRows INT = 1
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN

	DECLARE @beID INT;
	DECLARE @iter INT = 0;
	DECLARE @localTran INT = 0;

	BEGIN TRY
		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END

		WHILE @iter < @GeneratedRows
		BEGIN
			EXEC dbo.miAddRandomEmployee @EmployeeType='EM', @beID=@beID;
			SET @iter = @iter +1;
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
END
