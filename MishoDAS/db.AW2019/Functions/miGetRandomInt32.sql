CREATE FUNCTION [dbo].[miGetRandomInt32]
(
	@minVal int,
	@maxVal int
)
RETURNS INT
AS EXTERNAL NAME MishoClr.MishoRandomData.GetInt32
