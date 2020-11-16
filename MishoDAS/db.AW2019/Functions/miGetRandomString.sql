CREATE FUNCTION [dbo].[miGetRandomString]
(
	@sMaxSize int,
	@IsFixed int = 0
)
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME MishoClr.MishoRandomData.GetString
