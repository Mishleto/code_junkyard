CREATE FUNCTION [dbo].[miGetExecutionsCount]
(
	@ProcedureName NVARCHAR(400),
	@IntervalType TINYINT
)
RETURNS INT
AS
BEGIN
	
	DECLARE 
		@result INT,
		@dtNow DATETIME = GETDATE(),
		@dtFilter DATETIME;

	IF @IntervalType = 1 -- this hour
		SET @dtFilter = DATEADD(hour, DATEDIFF(hour, 0, @dtNow), 0);
	ELSE IF @IntervalType = 2 -- Today
		SET @dtFilter = DATEADD(day, DATEDIFF(day, 0, @dtNow), 0);
	ELSE IF @IntervalType = 3 -- This week
		SET @dtFilter = DATEADD(week, DATEDIFF(week, 0, @dtNow), 0);
	ELSE IF @IntervalType = 4 -- This Month
		SET @dtFilter = DATEADD(month, DATEDIFF(month, 0, @dtNow), 0);
	ELSE IF @IntervalType = 5 -- This Year
		SET @dtFilter = DATEADD(year, DATEDIFF(year, 0, @dtNow), 0);
	ELSE
		RETURN CAST('Inccorect Value provided for parameter @IntervalType. Enter value between 1 and 5 incl.' as int);

	SELECT 
		@Result = count(*)
	FROM dbo.miProcedureLogs pl
	WHERE pl.Status <> 'ERROR'
		and pl.ProcedureName = @ProcedureName
		and pl.StartTime >  @dtFilter;

	RETURN @result;

END;