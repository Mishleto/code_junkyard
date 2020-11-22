CREATE FUNCTION [dbo].[miGetRandomAlphaString]
(
	@sMaxSize int,
	@IsFixed int
)
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME MishoClr.MishoRandomData.GetAlphaString
