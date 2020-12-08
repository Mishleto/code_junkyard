CREATE PROCEDURE [dbo].[miGenEmployees]
	@GeneratedRows INT = 1
AS
BEGIN 
	IF @GeneratedRows < 1
		RETURN 0

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT,
		@Iter INT = 0;

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		WHILE @Iter < @GeneratedRows
		BEGIN
			EXEC dbo.miAddRandomEmployee;
			SET @Iter = @Iter +1;
		END;

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