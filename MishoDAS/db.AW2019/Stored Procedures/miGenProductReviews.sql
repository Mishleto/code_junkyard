CREATE PROCEDURE [dbo].[miGenProductReviews]
	@GeneratedRows int = 1
AS
BEGIN

	DECLARE @localTran BIT = 0;

	BEGIN TRY

		IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @localTran = 1;
		END;

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

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;
		
		EXECUTE [dbo].[uspLogError];
		RETURN -1
	END CATCH

	RETURN 0
END;
