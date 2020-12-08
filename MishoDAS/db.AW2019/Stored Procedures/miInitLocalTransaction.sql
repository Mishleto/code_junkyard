CREATE PROCEDURE [dbo].[miInitLocalTransaction]
	@LocalTranFlag BIT OUTPUT
AS
BEGIN
	IF @@TRANCOUNT = 0
	BEGIN
		BEGIN TRANSACTION;
		SET @LocalTranFlag = 1;
	END
	ELSE
		SET @LocalTranFlag = 0;
END;

