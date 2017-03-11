/***********************************************************************
Copyright 2016, Kendra Little - littlekendra.com
MIT License, http://www.opensource.org/licenses/mit-license.php
***********************************************************************/

/***********************************************************************
FIRST, TELL SQL SERVER TO ISSUE THE BLOCKED PROCESS REPORT
***********************************************************************/

/* Check if there are any pending configuration items before you start */
/* Take care of those before proceeding if they exist */

SELECT *
FROM sys.configurations
where value <> value_in_use;
GO

/* Show 'advanced options' -- the BPR setting is advanced!  */
/* Warning: RECONFIGURE pushes through ALL pending changes! */

IF (SELECT value_in_use FROM sys.configurations
	where name=N'show advanced options') <> 1
BEGIN
	EXEC ('EXEC sp_configure ''show advanced options'', 1;');
	EXEC ('RECONFIGURE');
END


/* Set the blocked process threshold (seconds) to a value of 5 */
/* or higher to tell SQL Server to issue blocked process reports. */
/* Set this back to 0 at any time to stop blocked process reports. */
EXEC sp_configure 'blocked process threshold (s)', 5;
GO
RECONFIGURE;
GO


/* You're not done-- you must configure a trace to pick up the 
Blocked Process Report. 
You may use either:
	* SQL Trace (server side trace recommended)
	* Extended Events 
*/