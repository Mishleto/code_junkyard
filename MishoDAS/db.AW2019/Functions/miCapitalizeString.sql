CREATE FUNCTION [dbo].[miCapitalizeString]
(
	@input NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME MishoClr.StringProcessor.Capitalize
