REFERENCES:
https://sqlwithmanoj.com/2010/09/29/database-mail-setup-sql-server-2005/
http://www.databasejournal.com/features/mssql/article.php/3626056/Database-Mail-in-SQL-Server-2005.htm

--Set the Database Mail Profile Name : Database_Backup and Account Name : Database_Backup

-----START--------------################CONFIGURE DATABASE FOR THE DBMAIL #############################--------------------

/*
PARAMETER: 
BANKSMART --> NAME OF DATABASE WHERE TO SET DBMAIL
*/

--BRFORE RUN THIS COMMAND THE DATABASE SHOULD NOT HAVE EXTERNAL CONNECTIONS. 
--SO STOP ALL APPLICATION THAT CONNECT TO DATABASE OR SET THE DATBASE TO SINGLE USER MODE.

USE [master]
GO
ALTER DATABASE BANKSMART SET  ENABLE_BROKER WITH NO_WAIT
GO  


EXEC sp_configure 'show advanced options', 1
RECONFIGURE

sp_configure 'Database Mail XPs',1
reconfigure

------END-------------################CONFIGURE DATABASE FOR THE DBMAIL #############################--------------------



-----@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-----

------START------------------##################  PROCEDURE TO BACKUP DATABASE ###################------------------------
/*
PARAMETERS : 
'D:\BANKSMART_BACKUP' --> DRIVE LOCATION WHERE BACKUP FILE WILL REMAINS
'BANKSMART_' --> BACKUP FILE NAME ALONG WITH THE DATE CONCATINATED.	
'.bak' --> BACKUP FILE EXTENSIONS
*/

USE BANKSMART
GO

CREATE  PROCEDURE [dbo].[SP_DATABASE_BACKUP]
AS
BEGIN
    DECLARE @filename VARCHAR(255)
SET @filename = 'D:\BANKSMART_BACKUP\BANKSMART_'+CONVERT(VARCHAR(10),GETDATE(),121) + '.bak'
BACKUP DATABASE BANKSMART TO DISK = @filename  
END;
GO
-----END-------------------##################  PROCEDURE TO BACKUP DATABASE ###################------------------------



-----@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-----

----START-----------------##################  SQL SERVER AGENT ALERT SETUP  ###################------------------------

USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'Database_Backup', 
		@notificationmethod=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, 
		@databasemail_profile=N'Database_Backup'
GO

----END-----------------##################  SQL SERVER AGENT ALERT SETUP  ###################-------------------------



--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--

----START-------------##################  OPERATORS SCTIPT FOR NOTIFICATION ###################-----------------------

USE [msdb]
GO

/****** Object:  Operator [Database_Backup]    Script Date: 2017-05-27 10:44:26 PM ******/
EXEC msdb.dbo.sp_add_operator @name=N'Database_Backup', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'suman.pantha@f1soft.com', 
		@category_name=N'[Uncategorized]'
GO


----END-------------##################  OPERATORS SCTIPT FOR NOTIFICATION ###################------------------------





-----@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@----

-----START-----------------------##################  SCHEDULAR JOB SCRIPT ###################-------------------------
--SCHEDULE AT 11 PM EVERY DAY

USE [msdb]
GO

/****** Object:  Job [Database_Backup]    Script Date: 2017-05-27 10:41:46 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 2017-05-27 10:41:46 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Database_Backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Database_Backup', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Database_Backup]    Script Date: 2017-05-27 10:41:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Database_Backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC SP_DATABASE_BACKUP', 
		@database_name=N'BANKSMART', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Database_Backup', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20170525, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=235959, 
		@schedule_uid=N'def4a2f4-07de-472d-a4bb-c9d783c3d3bf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
----END--------------------##################  SCHEDULAR JOB SCRIPT ###################-----------------------------



--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@---

--NOTE:
--IF THE MESSAGE IS NOT DELIVERED THE STOP START THE DBMAIL
exec dbo.sysmail_start_sp
exec dbo.sysmail_stop_sp
