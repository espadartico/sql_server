/*	
	Enable Query Store and clear out history
	(just because we're restoring a sample DB)
*/
USE [master];
GO
ALTER DATABASE [WideWorldImporters] SET QUERY_STORE = ON;
GO
ALTER DATABASE [WideWorldImporters] SET QUERY_STORE (
OPERATION_MODE = READ_WRITE,
CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30),
DATA_FLUSH_INTERVAL_SECONDS = 60,
INTERVAL_LENGTH_MINUTES = 60,
MAX_STORAGE_SIZE_MB = 512,
QUERY_CAPTURE_MODE = ALL,
SIZE_BASED_CLEANUP_MODE = AUTO,
MAX_PLANS_PER_QUERY = 200);
GO

ALTER DATABASE [WideWorldImporters] SET QUERY_STORE CLEAR;
GO

/*
	Create procedure for testing
	Sample values (CustomerID, SalespersonPersonID):
		90, 16
		804, 20
		910, 6
*/
USE [WideWorldImporters];
GO

DROP PROCEDURE IF EXISTS [Sales].[usp_GetOrderInfo];
GO

CREATE PROCEDURE [Sales].[usp_GetOrderInfo]
	@CustomerID INT, @SalespersonPersonID INT
AS

	SELECT
		[o].[CustomerID],
		[o].[SalespersonPersonID],
		[o].[OrderDate],
		[ol].[StockItemID],
		[ol].[Quantity],
		[ol].[UnitPrice]
	FROM [WideWorldImporters].[Sales].[Orders] [o]
	JOIN [WideWorldImporters].[Sales].[OrderLines] [ol] on [o].[OrderID] = [ol].[OrderID]
	WHERE [o].[CustomerID] = @CustomerID
		AND [o].[SalespersonPersonID] = @SalespersonPersonID
	ORDER BY [o].[OrderDate] DESC;

GO

/*
	Testing different CEs
	Context matters:
		http://www.sqlskills.com/blogs/erin/sql-server-2016-upgrade-testing-with-the-new-cardinality-estimator-context-matters/
	*Enable actual plan
*/
USE [master];
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 110;
GO

USE [WideWorldImporters];
GO
EXEC [Sales].[usp_GetOrderInfo] 804, 20;
/*
	Plan shows old CE (CardinalityEstimationModelVersion="70")
*/

USE [master];
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 130;
GO

USE [WideWorldImporters];
GO
EXEC [Sales].[usp_GetOrderInfo] 804, 20;
/*
	Plan shows old CE (CardinalityEstimationModelVersion="130")
*/

/*
	How to find in Query Store?
*/
USE [WideWorldImporters];
GO

EXEC sp_query_store_flush_db;
GO

/*
	Queries using old CE
*/
SELECT
	[qst].[query_text_id], [qsq].[query_id], [qsp].[plan_id], [qsq].[is_internal_query], [qsq].[object_id],
	[qsq].[count_compiles], [qsp].[engine_version], [qsp].[compatibility_level], [qsp].[is_parallel_plan],
	[qsp].[is_forced_plan], [qsp].[is_trivial_plan], [qsp].[last_compile_duration], [qsp].[last_execution_time],
	[qst].[statement_sql_handle], [qsq].[query_hash], [qsp].[query_plan_hash], [qst].[query_sql_text], [qsp].[query_plan]
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_plan] [qsp] ON [qsq].query_id = [qsp].query_id
JOIN [sys].[query_store_query_text] [qst] ON [qsq].query_text_id = [qst].query_text_id
WHERE [qsp].[compatibility_level] < 120;

/*
	Queries using old CE (and any variations using the new one too)
*/
SELECT
	[qst].[query_text_id], [qsq].[query_id], [qsp].[plan_id], [qsq].[is_internal_query], [qsq].[object_id],
	[qsq].[count_compiles], [qsp].[engine_version], [qsp].[compatibility_level], [qsp].[is_parallel_plan],
	[qsp].[is_forced_plan], [qsp].[is_trivial_plan], [qsp].[last_compile_duration], [qsp].[last_execution_time],
	[qst].[statement_sql_handle], [qsq].[query_hash], [qsp].[query_plan_hash], [qst].[query_sql_text], [qsp].[query_plan]
FROM [sys].[query_store_query_text] [qst]
JOIN [sys].[query_store_query] [qsq] on [qst].[query_text_id] = [qsq].[query_text_id]
JOIN [sys].[query_store_plan] [qsp] on [qsq].query_id = [qsp].query_id
WHERE [qsq].[query_id] IN
( SELECT 
	[qsq].[query_id]
FROM [sys].[query_store_query] [qsq]
JOIN [sys].[query_store_plan] [qsp] on [qsq].query_id = [qsp].query_id
WHERE [qsp].[compatibility_level] < 120)
ORDER BY [qsp].[compatibility_level];

/*
	Change the SP to use QUERYTRACEON hint
	and force the new CE with TF 2312
		*See Kimberly's recent post about setting
		CE TF's per query or session:
		http://www.sqlskills.com/blogs/kimberly/sp_settraceflag/
*/
USE [WideWorldImporters];
GO

DROP PROCEDURE IF EXISTS [Sales].[usp_GetOrderInfo];
GO

CREATE PROCEDURE [Sales].[usp_GetOrderInfo]
	@CustomerID INT, @SalespersonPersonID INT
AS

	SELECT
		[o].[CustomerID],
		[o].[SalespersonPersonID],
		[o].[OrderDate],
		[ol].[StockItemID],
		[ol].[Quantity],
		[ol].[UnitPrice]
	FROM [WideWorldImporters].[Sales].[Orders] [o]
	JOIN [WideWorldImporters].[Sales].[OrderLines] [ol] on [o].[OrderID] = [ol].[OrderID]
	WHERE [o].[CustomerID] = @CustomerID
		AND [o].[SalespersonPersonID] = @SalespersonPersonID
	ORDER BY [o].[OrderDate] DESC
	OPTION (QUERYTRACEON 2312);

GO

USE [master];
GO
ALTER DATABASE [WideWorldImporters] SET COMPATIBILITY_LEVEL = 110;
GO

USE [WideWorldImporters];
GO

/*
	Plan shows new CE (CardinalityEstimationModelVersion="120")
	even though database compat is 110
	Note: TF 2312 is compat mode 120 only (not 130)
*/
EXEC [Sales].[usp_GetOrderInfo] 804, 20;