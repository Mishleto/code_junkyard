CREATE FUNCTION [dbo].[miGetRandomIntTable]
(
	@rowsCount int,
	@minVal int,
	@maxVal int
)
RETURNS TABLE
(
	RndVal int
)
AS EXTERNAL NAME MishoClr.MishoRandomData.GetIntTable