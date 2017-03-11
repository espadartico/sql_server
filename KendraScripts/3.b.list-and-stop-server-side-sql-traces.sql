/***********************************************************************
NOT SURE HOW MANY SERVER SIDE TRACES OR PROFILER TRACES YOU'RE RUNNING? 
USE THIS TO CHECK, AND POSSIBLY STOP AND DELETE.
***********************************************************************/


/* Want to clean up a server side trace for the Blocked Process Report, or anything else?  */

/* This will list all Server Side Traces (whether or not they have started)    */
/* The default trace is usually trace id=1, 
	it will show as having no stop time and have a path like
	D:\MSSQL\DATA\MSSQL13.MSSQLSERVER\MSSQL\Log\log_123.trc 
*/
SELECT *
FROM sys.traces;
GO

/* To stop a trace, get the id from the query above */
/* Stop the trace by setting it to status = 0 */
EXEC sp_trace_setstatus @traceid = ? , @status = 0; 
GO

/* Delete the trace by setting the status to 2 */
EXEC sp_trace_setstatus @traceid = ? , @status = 2; 
GO