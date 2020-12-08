CREATE PROCEDURE [dbo].[miGenAllRandomData]
AS
BEGIN

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT,
		@rowCountBase TINYINT = 5,
		@ExtraRows TINYINT = 2,
		@rowCountExtra TINYINT;

	SET @rowCountExtra = @rowCountBase + @ExtraRows;
	
	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		EXEC dbo.miInitLocalTransaction @LocalTranFlag OUTPUT;
		
		EXEC sys.sp_set_session_context @key=N'PARENT_LOG_ID', @value=@LogID, @read_only=1; 
		

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