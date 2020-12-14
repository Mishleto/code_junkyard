CREATE PROCEDURE [dbo].[miGenAllRandomData]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE 
		@LocalTranFlag BIT,
		@LogID INT,
		@qDBName VARCHAR(128) = QUOTENAME(DB_NAME()),
		@rowCountBase TINYINT = 5,
		@ExtraRows TINYINT = 2,
		@rowCountExtra TINYINT;

	SET @rowCountExtra = @rowCountBase + @ExtraRows;
	
	BEGIN TRY
		EXEC dbo.miLogProcedureStart @ProcedureID = @@PROCID, @LogID = @LogID OUTPUT;
		 IF @@TRANCOUNT = 0
		BEGIN
			BEGIN TRANSACTION;
			SET @LocalTranFlag = 1;
		END;
		
		EXEC sys.sp_set_session_context @key=N'PARENT_LOG_ID', @value=@LogID, @read_only=1; 
		

		-----------------------------------------------------------------------------
		-- Executed at most once a  hour

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenIndividualCustomers]',1) = 0
			EXEC dbo.miGenIndividualCustomers @GeneratedRows=@rowCountBase;
		
		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenCustomers]',1) = 0
			EXEC dbo.miGenCustomers @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenCreditCards]',1) = 0
			EXEC dbo.miGenCreditCards @GeneratedRows=@rowCountExtra;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenAddresses]',1) = 0
			EXEC dbo.miGenAddresses @GeneratedRows=@rowCountExtra;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenBusinessEntityAddresses]',1) = 0
			EXEC dbo.miGenBusinessEntityAddresses @GeneratedRows=@rowCountExtra;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenEmailAddresses]',1) = 0
			EXEC dbo.miGenEmailAddresses @GeneratedRows=@rowCountExtra; 

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenPersonCreditCards]',1) = 0
			EXEC dbo.miGenPersonCreditCards @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenPersonPhones]',1) = 0
			EXEC dbo.miGenPersonPhones @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenPurchaseOrders]',1) = 0
			EXEC dbo.miGenPurchaseOrders @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenPurchaseOrderUpdate]',1) = 0
			EXEC dbo.miGenPurchaseOrderUpdate @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenSalesOrder]',1) = 0
			EXEC dbo.miGenSalesOrder @GeneratedRows=@rowCountBase;
		
		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenSalesOrderUpdates]',1) = 0
			EXEC dbo.miGenSalesOrderUpdates @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenWorkOrders]',1) = 0
			EXEC dbo.miGenWorkOrders @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenWorkOrdersUpdate]',1) = 0
			EXEC dbo.miGenWorkOrdersUpdate @GeneratedRows=@rowCountBase;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenProductReviews]',1) = 0
			EXEC dbo.miGenProductReviews @GeneratedRows=1;

		-----------------------------------------------------------------------------

		
		
		-----------------------------------------------------------------------------
		-- Executed at most once a day

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenCurrencyRates]',2) = 0
			EXEC dbo.miGenCurrencyRates;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenEmpDepartmentHistory]',2) = 0
			EXEC dbo.miGenEmpDepartmentHistory @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenEmpPayHistory]',2) = 0
			EXEC dbo.miGenEmpPayHistory @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenProductCostHistory]',2) = 0
			EXEC dbo.miGenProductCostHistory @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenProductInventory]',2) = 0
			EXEC dbo.miGenProductInventory @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenProductListPriceHistory]',2) = 0
			EXEC dbo.miGenProductListPriceHistory @GeneratedRows=1;
		
		-----------------------------------------------------------------------------
		


		-----------------------------------------------------------------------------
		-- Executed at most once a week

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenEmployees]',3) = 0
			EXEC dbo.miGenEmployees @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenSalesPeople]',3) = 0
			EXEC dbo.miGenSalesPeople @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenProductDescriptions]',3) = 0
			EXEC dbo.miGenProductDescriptions @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenProductModel]',3) = 0
			EXEC dbo.miGenProductModel @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenStores]',3) = 0
			EXEC dbo.miGenStores @GeneratedRows=1;

		IF dbo.miGetExecutionsCount(@qDBName + '.[dbo].[miGenVendors]',3) = 0
			EXEC dbo.miGenVendors @GeneratedRows=1;
		
		-----------------------------------------------------------------------------

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