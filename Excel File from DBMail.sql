DECLARE
    @tab char(1) = CHAR(9)

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DatabaseBackup',   -- replace with your SQL Database Mail Profile 
    @recipients = 'hrtpantha@gmail.com',
    @query = 'SET NOCOUNT ON 
              select AgentCode,AgentName,ltrim(PhoneNumber) AS PhoneNumber, Email, convert(varchar(10), CreatedDate,121)  as CreatedDate from MMESV2DBUAT..Agent',
    @subject = 'RA results',
    @attach_query_result_as_file = 1,
    @query_attachment_filename='RATEST.CSV',
    @query_result_separator=@tab,
    @query_result_no_padding=1
