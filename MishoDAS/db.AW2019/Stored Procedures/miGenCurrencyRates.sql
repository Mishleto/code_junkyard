CREATE PROCEDURE [dbo].[miGenCurrencyRates]
AS
BEGIN

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;

	DECLARE @LastRates TABLE (
			fc_code nchar(3),
			tc_code nchar(3),
			crd date,
			avg_rate money,
			eod_rate money);

	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into @LastRates
		SELECT 
			cr.FromCurrencyCode,
			cr.ToCurrencyCode,
			cr.CurrencyRateDate,
			cr.AverageRate,
			cr.EndOfDayRate
		FROM (
			SELECT 
				c.*,
				ROW_NUMBER() over (partition by FromCurrencyCode, ToCurrencyCode order by CurrencyRateDate desc) rn
			FROM Sales.CurrencyRate c
		) cr
		WHERE cr.rn = 1;	

		with xrates(fc_code, tc_code, crd, avg_rate, eod_rate, coeff, lvl) as
		(
			select 
				fc_code, tc_code, crd, avg_rate, eod_rate, 
				cast(1 + 0.005*dbo.miGetRandomInt32(1,2) as money) as coeff,
				1 as lvl
			from @LastRates
			union all
			select 
				fc_code, tc_code,
				dateadd(day,1,crd),
				cast(avg_rate * coeff as money),
				cast(eod_rate * coeff as money),
				cast(1 + 0.005*dbo.miGetRandomInt32(-1,2) as money),
				lvl+1 as lvl 
			from xrates
			where crd < CAST(DATEADD(day,1,getdate()) as DATE)
		)
		INSERT into Sales.CurrencyRate(CurrencyRateDate, FromCurrencyCode, ToCurrencyCode, AverageRate, EndOfDayRate)
		select 
			crd, fc_code, tc_code, avg_rate, eod_rate
		from xrates 
		where lvl > 1
		option (maxrecursion 5000);

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