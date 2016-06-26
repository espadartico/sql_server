-- If the Event Session exists DROP it
IF EXISTS (SELECT 1 
            FROM sys.server_event_sessions 
            WHERE name = 'SQLskills_TrackPageSplits')
    DROP EVENT SESSION [SQLskills_TrackPageSplits] ON SERVER

-- Create the Event Session to track LOP_DELETE_SPLIT transaction_log operations in the server
CREATE EVENT SESSION [SQLskills_TrackPageSplits]
ON    SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT 
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'database_id');
GO
        
-- Start the Event Session
ALTER EVENT SESSION [SQLskills_TrackPageSplits]
ON SERVER
STATE=START;
GO

-- Drop the Event Session so we can recreate it 
-- to focus on the highest splitting database
DROP EVENT SESSION [SQLskills_TrackPageSplits] 
ON SERVER

-- Create the Event Session to track LOP_DELETE_SPLIT transaction_log operations in the server
CREATE EVENT SESSION [SQLskills_TrackPageSplits]
ON    SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT 
      AND database_id = 7 -- CHANGE THIS BASED ON TOP SPLITTING DATABASE!
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'alloc_unit_id');
GO

-- Start the Event Session Again
ALTER EVENT SESSION [SQLskills_TrackPageSplits]
ON SERVER
STATE=START;
GO