CREATE PROCEDURE [dbo].[miGenCreditCards]
	@param1 int = 0,
	@param2 int
AS
	SELECT @param1, @param2
RETURN 0

SELECT *
FROM Person.AddressType
GO