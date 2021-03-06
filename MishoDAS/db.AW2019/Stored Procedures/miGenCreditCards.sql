﻿CREATE PROCEDURE [dbo].[miGenCreditCards]
	@GeneratedRows int = 5
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;

		with 
		CardsDesc (MinCoeff, MaxCoeff, TypeDesc, TypePreff) as
		(
			SELECT 0, 245, 'Vista', '1111' UNION ALL 
			SELECT 245, 490, 'SuperiorCard', '3333' UNION ALL
			SELECT 490, 735, 'Distinguish', '5555' UNION ALL
			SELECT 735, 980, 'ColonialVoice', '7777' UNION ALL
			SELECT 980, 990, 'Кофти_име', '' UNION ALL
			SELECT 990, 1000, 'Vista', '111112'
		)
		INSERT 
		into Sales.CreditCard(CardType,CardNumber,ExpMonth,ExpYear)
		select 
			cd.TypeDesc,
			cd.TypePreff + CAST(dbo.miGetRandomInt32(10000,99999) as VARCHAR) + CAST(dbo.miGetRandomInt32(10000,99999) as VARCHAR),
			IIF(rit.RndVal % 3 > 0, 
				dbo.miGetRandomInt32(1,13),
				dbo.miGetRandomInt32(1,14)
			) as ExpMonth,										-- 1/(3*13) chance of error data
			IIF(rit.RndVal % 50 > 0, 
				dbo.miGetRandomInt32(1,3),
				dbo.miGetRandomInt32(-5,-1)
			) + YEAR(GETDATE())  as  ExpYear					-- 1/50 chance of error data
		from dbo.miGetRandomIntTable(@GeneratedRows,0,1000) rit
			inner join CardsDesc cd on rit.RndVal >= cd.MinCoeff
									and rit.RndVal < cd.MaxCoeff
		OPTION (FORCE ORDER);

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