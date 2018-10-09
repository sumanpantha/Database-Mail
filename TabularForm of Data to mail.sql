DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)

SET @xml = CAST(( SELECT [AgentCode] AS 'td','',[AgentName] AS 'td','', [PhoneNumber] AS 'td','',ISNULL([Email],'N/A' )AS 'td','',[CreatedDate]
FROM MMESV2DBUAT..Agent
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))


SET @body ='<html><body><H3>Agent Report</H3>
<table border = 1> 
<tr>
<th> Agent Code </th> <th> Agent Name </th> <th> Phone Number </th>  <th> Email </th>  <th> Created Date </th>     </tr>'    
 
SET @body = @body + @xml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'DatabaseBackup', -- replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@query_attachment_filename= 'DailyReport.csv',
@recipients = 'hrtpantha@gmail.com', -- replace with your email address
@subject = 'E-mail in Tabular Format' ;
