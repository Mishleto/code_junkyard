CREATE FUNCTION [dbo].[miGetRandomAlphaNumString]
(
	@sMaxSize int,
	@IsFixed int = 0
)
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME MishoClr.MishoRandomData.GetAlphanumString