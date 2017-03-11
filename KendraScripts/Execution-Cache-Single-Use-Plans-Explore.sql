/***********************************************************
TSQL to do a quick and dirty look at single-use plans in 
the execution plan cache of a SQL Server. 
************************************************************/

/* Size of single use adhoc plans in execution plan cache */
SELECT 
    objtype, 
    cacheobjtype, 
    SUM(size_in_bytes)/1024./1024. as [MB] 
FROM sys.dm_exec_cached_plans   
WHERE usecounts = 1
    and objtype = 'Adhoc'
GROUP BY objtype, cacheobjtype;
GO

/* Explore the queries generating the single use adhoc plans */
/* In some cases, I have found single use adhoc plans to all come from one or two bits of code.
In those cases, it can be more effective in the long term to fix the code and make it reuse plans
(it's usually an accident that it wasn't properly parameterized that way). */
SELECT 
    cacheobjtype, 
    [text] as [sql text], 
    size_in_bytes/1024. as [KB] 
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_sql_text(plan_handle)   
WHERE 
    usecounts = 1
    and objtype = 'Adhoc'
ORDER BY [KB] DESC;  
GO  

/* Put single use adhoc plans into context of the whole plan cache */
/* When 'Optimize for Adhoc Workloads' is enabled, you'll see a row in 
    this list with objtype=Adhoc, cacheobjtype=Compiled Plan Stub.
    Those are the number and size used by the plan "stubs" of queries
    that have just run once since the setting was enabled / instance
    restart
*/
SELECT 
    objtype, 
    cacheobjtype, 
    SUM(CASE usecounts WHEN 1 THEN
        1 
    ELSE 0 END ) AS [Count: Single Use Plans],
    SUM(CASE usecounts WHEN 1 THEN
        size_in_bytes 
    ELSE 0 END )/1024./1024. AS [MB: Single Use Plans],
    COUNT_BIG(*) as [Count: All Plans],
    SUM(size_in_bytes)/1024./1024. AS [MB - All Plans] 
FROM sys.dm_exec_cached_plans   
GROUP BY objtype, cacheobjtype;
GO

/* Other queries for this from around the web:

Kimberly Tripp: http://www.sqlskills.com/blogs/kimberly/plan-cache-and-optimizing-for-adhoc-workloads/
Robert Davis: http://www.sqlservercentral.com/blogs/robert_davis/2010/04/23/Looking-forward-to-Optimize-for-Ad-hoc-Workloads-in-Sql-Server-2008/
*/
