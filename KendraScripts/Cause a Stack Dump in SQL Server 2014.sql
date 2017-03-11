/* This doesn't cause a stack dump in SQL Server 2016 SP1-- looks like
it broke in 2012 and was fixed sometime before 2016 SP1

*/

Use AdventureWorks2012;
GO

CREATE INDEX ix_poorly_named_filtered_index on
Sales.SalesOrderHeader (OrderDate)
WHERE (Comment IS NOT NULL);
GO

SELECT ind.name as index_name, 
    page_level,
    allocated_page_page_id, allocated_page_file_id, is_allocated
FROM sys.dm_db_database_page_allocations (
    DB_ID(), OBJECT_ID('Sales.SalesOrderHeader'), NULL, NULL, 'detailed') as alloc
JOIN sys.indexes as ind on 
    alloc.object_id=ind.object_id and
    alloc.index_id=ind.index_id
WHERE 
    --ind.name = 'ix_poorly_named_filtered_index'
    page_type_desc='INDEX_PAGE'
GO


DBCC TRACEON (3604);
GO

DBCC PAGE (AdventureWorks2012, 1, 6824, 3);
GO