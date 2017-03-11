/***********************************************************************
NOT SURE HOW MANY XEVENTS TRACES YOU'RE RUNNING? 
USE THIS TO CHECK, AND POSSIBLY STOP AND DELETE.
***********************************************************************/

/* List Extended Events Traces which are currently started. 
Built-in sessions include:
	system_health
	sp_server_diagnostics session
	hkenginexesession
	telemetry_xevents
*/
SELECT
	name, 
	pending_buffers,
	create_time, 
	session_source
FROM sys.dm_xe_sessions;
GO

/* Plug the trace name you want to stop and drop into
the commands below */

ALTER EVENT SESSION [Blocked Process Report]  
	ON SERVER  
	STATE = STOP;  
GO

DROP EVENT SESSION [Blocked Process Report] ON SERVER 
GO