CREATE PROCEDURE [dbo].[miGenAllRandomData]
AS
BEGIN

	DECLARE @localTran BIT = 0;
	DECLARE @jobID INT;
	DECLARE @jobName VARCHAR(50) = 'GEN_ALL_RANDOM_DATA'
	DECLARE @jobInfo VARCHAR(1000) = null;
	DECLARE @ErrorLogID INT;
	
	DECLARE @rowCountBase TINYINT = 5;
	DECLARE @ExtraRows TINYINT = 2;
	DECLARE @rowCountExtra TINYINT = @rowCountBase + @ExtraRows;
	
	BEGIN TRY

		EXEC sys.sp_set_session_context @key=N'ParentJobId', @value=@jobId, @read_only=1; 
		
		

		-- CALLED ONCE PER HOUR
		EXEC dbo.miGenIndividualCustomers @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenCustomers @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenCreditCards @GeneratedRows=@rowCountExtra;

		EXEC dbo.miGenAddresses @GeneratedRows=@rowCountExtra;
		EXEC dbo.miGenBusinessEntityAddresses @GeneratedRows=@rowCountExtra;
		EXEC dbo.miGenEmailAddresses @GeneratedRows=@rowCountExtra; 
		EXEC dbo.miGenPersonCreditCards @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenPersonPhones @GeneratedRows=@rowCountBase;

		EXEC dbo.miGenPurchaseOrders @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenPurchaseOrderUpdate @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenSalesOrder @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenSalesOrderUpdates @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenWorkOrders @GeneratedRows=@rowCountBase;
		EXEC dbo.miGenWorkOrdersUpdate @GeneratedRows=@rowCountBase;

		EXEC dbo.miGenProductReviews @GeneratedRows=1;
		
		
		-- CALLED ONCE PER DAY 
		EXEC dbo.miGenCurrencyRates;
		EXEC dbo.miGenEmpDepartmentHistory @GeneratedRows=1;
		EXEC dbo.miGenEmpPayHistory @GeneratedRows=1;
		EXEC dbo.miGenProductCostHistory @GeneratedRows=1;
		EXEC dbo.miGenProductInventory @GeneratedRows=1;
		EXEC dbo.miGenProductListPriceHistory @GeneratedRows=1;
		
		
		--ONCE A WEEK
		EXEC dbo.miGenEmployees @GeneratedRows=1;
		EXEC dbo.miGenSalesPeople @GeneratedRows=1;
		EXEC dbo.miGenProductDescriptions @GeneratedRows=1;
		EXEC dbo.miGenProductModel @GeneratedRows=1;
		EXEC dbo.miGenStores @GeneratedRows=1;
		EXEC dbo.miGenVendors @GeneratedRows=1;
		

		IF @localTran = 1
			COMMIT;
	END TRY

	BEGIN CATCH
		IF @localTran = 1
			ROLLBACK;
		
		EXECUTE [dbo].[uspLogError] @ErrorLogID = @ErrorLogID;
		RETURN -1
	END CATCH

	RETURN 0
END;