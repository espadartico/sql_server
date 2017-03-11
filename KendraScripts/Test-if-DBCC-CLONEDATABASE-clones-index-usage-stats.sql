SET NOCOUNT ON;
GO

use master;
GO
IF DB_ID('CloneMe') IS NOT NULL
BEGIN
    ALTER DATABASE CloneMe SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CloneMe;
END
GO

IF DB_ID('IAmAClone') IS NOT NULL
BEGIN
    ALTER DATABASE IAmAClone SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE IAmAClone;
END
GO

CREATE DATABASE CloneMe;
GO

USE CloneMe;
GO

CREATE TABLE dbo.SomeTable (
	UniqueCol BIGINT IDENTITY,
	DateCol DATE NOT NULL DEFAULT (GetDate()),
	Col1 CHAR(256) DEFAULT ('Somevalue'),
	Col2 BIT DEFAULT (1),
	Col3 INT DEFAULT (123),
    CONSTRAINT pk_SomeTable_UniqueCol PRIMARY KEY CLUSTERED (UniqueCol) 
);
GO

CREATE INDEX ix_SomeTable_Col1_INCLUDES on dbo.SomeTable (Col1)
    INCLUDE (Col2, Col3);
GO

DECLARE @i INT = 1;
BEGIN TRAN
    WHILE @i <= 10000
    BEGIN
        INSERT dbo.SomeTable DEFAULT VALUES;
        SET @i=@i+1;
    END
COMMIT
GO

SELECT Col3
FROM dbo.SomeTable
WHERE Col1='Foo'
GO 10

SELECT COUNT(DISTINCT(Col3))
FROM dbo.SomeTable
WHERE 
    Col2 IS NOT NULL
GO 30

/* Simple index usage stats query for current database. */
SELECT 
    s.name as schema_name,
    o.name as object_name,
    i.name as index_name,
    i.type_desc,
    u.user_seeks + u.user_scans + u.user_lookups as user_read_operations,
    u.user_updates as user_write_operations,
    i.is_disabled,
    i.is_disabled,
    i.has_filter
FROM sys.indexes as i
JOIN sys.objects as o on 
    i.object_id=o.object_id
JOIN sys.schemas as s on 
    o.schema_id=s.schema_id
LEFT JOIN sys.dm_db_index_usage_stats AS u on 
    i.index_id = u.index_id
    and i.object_id = u.object_id
    and u.database_id=DB_ID()
WHERE o.is_ms_shipped = 0
ORDER BY 1,2,3,4;
GO

/* Simple missing index query for current database */
SELECT 
    d.statement as table_name,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.avg_total_user_cost as avg_est_cost_of_requesting_plan,
    s.avg_user_impact as avg_est_cost_reduction,
    s.user_scans + s.user_seeks as times_requested
FROM sys.dm_db_missing_index_groups AS g
JOIN sys.dm_db_missing_index_group_stats as s on
    g.index_group_handle=s.group_handle
JOIN sys.dm_db_missing_index_details as d on
    g.index_handle=d.index_handle
JOIN sys.databases as db on 
    d.database_id=db.database_id
WHERE db.database_id=DB_ID();
GO

/*Let's Clone it! */
DBCC CLONEDATABASE (CloneMe, IAmAClone);
GO

USE IAmAClone;
GO


/* Do we see the index usage stats? */
SELECT 
    s.name as schema_name,
    o.name as object_name,
    i.name as index_name,
    i.type_desc,
    u.user_seeks + u.user_scans + u.user_lookups as user_read_operations,
    u.user_updates as user_write_operations,
    i.is_disabled,
    i.is_disabled,
    i.has_filter
FROM sys.indexes as i
JOIN sys.objects as o on 
    i.object_id=o.object_id
JOIN sys.schemas as s on 
    o.schema_id=s.schema_id
LEFT JOIN sys.dm_db_index_usage_stats AS u on 
    i.index_id = u.index_id
    and i.object_id = u.object_id
    and u.database_id=DB_ID()
WHERE o.is_ms_shipped = 0
ORDER BY 1,2,3,4;
GO

/* Do we see the missing index requests? */
SELECT 
    d.statement as table_name,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.avg_total_user_cost as avg_est_cost_of_requesting_plan,
    s.avg_user_impact as avg_est_cost_reduction,
    s.user_scans + s.user_seeks as times_requested
FROM sys.dm_db_missing_index_groups AS g
JOIN sys.dm_db_missing_index_group_stats as s on
    g.index_group_handle=s.group_handle
JOIN sys.dm_db_missing_index_details as d on
    g.index_handle=d.index_handle
JOIN sys.databases as db on 
    d.database_id=db.database_id
WHERE db.database_id=DB_ID();
GO


/* Let's run our test queries against the clone...*/
SELECT Col3
FROM dbo.SomeTable
WHERE Col1='Foo'
GO 10

SELECT COUNT(DISTINCT(Col3))
FROM dbo.SomeTable
WHERE 
    Col2 IS NOT NULL
GO 30



/* Do we see the index usage stats? */
SELECT 
    s.name as schema_name,
    o.name as object_name,
    i.name as index_name,
    i.type_desc,
    u.user_seeks + u.user_scans + u.user_lookups as user_read_operations,
    u.user_updates as user_write_operations,
    i.is_disabled,
    i.is_disabled,
    i.has_filter
FROM sys.indexes as i
JOIN sys.objects as o on 
    i.object_id=o.object_id
JOIN sys.schemas as s on 
    o.schema_id=s.schema_id
LEFT JOIN sys.dm_db_index_usage_stats AS u on 
    i.index_id = u.index_id
    and i.object_id = u.object_id
    and u.database_id=DB_ID()
WHERE o.is_ms_shipped = 0
ORDER BY 1,2,3,4;
GO

/* Do we see the missing index requests? */
SELECT 
    d.statement as table_name,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.avg_total_user_cost as avg_est_cost_of_requesting_plan,
    s.avg_user_impact as avg_est_cost_reduction,
    s.user_scans + s.user_seeks as times_requested
FROM sys.dm_db_missing_index_groups AS g
JOIN sys.dm_db_missing_index_group_stats as s on
    g.index_group_handle=s.group_handle
JOIN sys.dm_db_missing_index_details as d on
    g.index_handle=d.index_handle
JOIN sys.databases as db on 
    d.database_id=db.database_id
WHERE db.database_id=DB_ID();
GO