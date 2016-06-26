USE [master];
GO
-- Drop the PageSplits database if it exists
IF DB_ID('PageSplits') IS NOT NULL
BEGIN
    ALTER DATABASE PageSplits SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PageSplits;
END
GO
-- Create the database
CREATE DATABASE PageSplits
GO
USE [PageSplits]
GO
-- Create a bad splitting clustered index table
CREATE TABLE BadSplitsPK
( ROWID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
  ColVal INT NOT NULL DEFAULT (RAND()*1000),
  ChangeDate DATETIME2 NOT NULL DEFAULT CURRENT_TIMESTAMP);
GO
--  This index should mid-split based on the DEFAULT column value
CREATE INDEX IX_BadSplitsPK_ColVal ON BadSplitsPK (ColVal);
GO
--  This index should end-split based on the DEFAULT column value
CREATE INDEX IX_BadSplitsPK_ChangeDate ON BadSplitsPK (ChangeDate);
GO
-- Create a table with an increasing clustered index
CREATE TABLE EndSplitsPK
( ROWID INT IDENTITY NOT NULL PRIMARY KEY,
  ColVal INT NOT NULL DEFAULT (RAND()*1000),
  ChangeDate DATETIME2 NOT NULL DEFAULT DATEADD(mi, RAND()*-1000, CURRENT_TIMESTAMP));
GO
--  This index should mid-split based on the DEFAULT column value
CREATE INDEX IX_EndSplitsPK_ChangeDate ON EndSplitsPK (ChangeDate);
GO
-- Insert the default values repeatedly into the tables / Run for couple of minutes
WHILE 1=1
BEGIN
    INSERT INTO dbo.BadSplitsPK DEFAULT VALUES;
    INSERT INTO dbo.EndSplitsPK DEFAULT VALUES;
    WAITFOR DELAY '00:00:00.005';
END
GO