CREATE PROCEDURE [dbo].[miGenProductReviews]
	@GeneratedRows int = 1
AS
BEGIN

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT;
	
	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;

		INSERT into Production.ProductReview(ProductID, ReviewerName, ReviewDate, EmailAddress, Rating, Comments)
		SELECT TOP(@GeneratedRows)
			ProductID,
			dbo.miCapitalizeString(dbo.miGetRandomAlphaString(6,1))
				+ ' ' + dbo.miCapitalizeString(dbo.miGetRandomAlphaString(6,1)) as ReviewerName,
			DATEADD(day, dbo.miGetRandomInt32(-10,0), GETDATE()) as ReviewDate,
			dbo.miGetRandomAlphaString(6,1) 
						+ '_' + dbo.miGetRandomAlphaNumString(8,0)
						+ '@mishomail.com' as EmailAddress,
			dbo.miGetRandomInt32(1,6) as Rating,
			dbo.miGetRandomAlphaString(10, 1) 
				+ ' ' + dbo.miGetRandomAlphaString(100, 0) as Comments
		FROM Production.Product
		ORDER BY dbo.miGetRandomInt32(1,1000);

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