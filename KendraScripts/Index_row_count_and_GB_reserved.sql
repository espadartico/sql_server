SELECT
    sc.name + N'.' + so.name as [Schema.Table],
	si.index_id as [Index ID],
	si.type_desc as [Structure],
    si.name as [Index],
    SUM(stat.row_count) AS [Rows],
    SUM(stat.in_row_reserved_page_count) * 8./1024./1024. as [Reserved In-Row GB],
	SUM(stat.lob_reserved_page_count) * 8./1024./1024. as [Reserved LOB GB]
FROM sys.indexes as si
JOIN sys.objects as so on si.object_id = so.object_id
JOIN sys.schemas as sc on so.schema_id = sc.schema_id
JOIN sys.dm_db_partition_stats as stat on stat.object_id=si.object_id
    and stat.index_id=si.index_id
WHERE so.is_ms_shipped = 0
GROUP BY
    sc.name + N'.' + so.name, 
    si.index_id, 
    si.type_desc,
    si.name
ORDER BY 1, 2, 3;
GO