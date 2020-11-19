﻿CREATE PROCEDURE [dbo].[miGenIndividualCustomers]
	@GeneratedRows int = 10
AS
BEGIN
	
	IF @GeneratedRows < 1
		RETURN

	DECLARE @iter int = 0;
	DECLARE @beID int;
	DECLARE @localTran BIT = 0;

	BEGIN TRY

		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END

		WHILE @iter < @GeneratedRows
		BEGIN
			EXEC dbo.miAddRandomPerson 'IN', @beID=@beID OUTPUT
			SET @iter = @iter +1;
		END;

		IF @localTran = 1
			COMMIT;

	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;

		EXECUTE [dbo].[uspLogError];
		RETURN -1
	END CATCH

	RETURN 0
END;