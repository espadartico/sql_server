-- Capture queries and Stored procedure queries on a specific DB and statement

CREATE EVENT SESSION [Capture_Query] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1), 
     collect_statement=(1)
    ACTION(sqlserver.client_app_name, 
     sqlserver.client_hostname,
     sqlserver.database_id,
     sqlserver.database_name,
     sqlserver.username,
	 sqlserver.sql_text,
	 sqlserver.plan_handle)
    WHERE (([object_type]=(8272)) 
     AND ([source_database_id]=(10)))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)
    WHERE ([sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%SQL_SERVER_PRD%') AND [package0].[equal_uint64]([sqlserver].[database_id],(10))))
ADD TARGET package0.event_file(SET filename=N'E:\Capture_Query.xel',max_file_size=(100))
WITH (MAX_MEMORY=128000 KB,EVENT_RETENTION_MODE=NO_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION [Capture_Query] ON SERVER STATE=START;

ALTER EVENT SESSION [Capture_Query] ON SERVER STATE=STOP;

DROP EVENT SESSION [Capture_Query] ON SERVER;

-- Select the events based on statement

with events_cte AS (
SELECT
xevents.event_data.value('(/event/@timestamp)[1]','datetime2') as [event time]
,xevents.event_data.value('(/event/@name)[1]','nvarchar(400)') as [event name]
,xevents.event_data.value('(/event/action[@name="username"])[1]','nvarchar(20)') as [username]
,xevents.event_data.value('(/event/action[@name="client_hostname"])[1]','nvarchar(50)') as [hostname]
,xevents.event_data.value('(/event/action[@name="client_app_name"])[1]','nvarchar(100)') as [app name]
,xevents.event_data.value('(/event/data[@name="duration"])[1]','bigint') as [duration]
,xevents.event_data.value('(/event/data[@name="cpu_time"])[1]','bigint') as [cpu time]
,xevents.event_data.value('(/event/data[@name="physical_reads"])[1]','bigint') as [physical reads]
,xevents.event_data.value('(/event/data[@name="logical_reads"])[1]','bigint') as [logical reads]
,xevents.event_data.value('(/event/data[@name="statement"]/value)[1]','nvarchar(4000)') as [statement]
,'0x'+UPPER(xevents.event_data.value('(/event/action[@name="plan_handle"]/value)[1]','nvarchar(4000)')) as [plan handle]
FROM sys.fn_xe_file_target_read_file('E:\Capture_Query*.xel', null, null, null)
CROSS APPLY (SELECT CAST(event_data as XML) as event_data) as xevents
)
SELECT * FROM events_cte
WHERE [statement] like '%sql_server_prd%'
ORDER BY [event time] DESC;