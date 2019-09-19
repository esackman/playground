# Sample code on Citrix 7.15 Controller Service Status check, fix and notification
asnp Citrix*

if ( (Get-PSSnapin -Name *Citrix*) -eq $null )
{
    Write-Error -Message "SnapIns not present" -Category InvalidResult
    exit
}
Else
{
    Write-Output "SnapIns available"
}

# Check "Citrix AD Identity Service" service status with Database

Write-Output "Checking Citrix Acct Service Status"

$AcctService = 'CitrixADIdentityService'
$AcctServiceStatus = Get-AcctServiceStatus

if ($AcctServiceStatus.ServiceStatus -ne 'OK')
{
    Write-Output "Issues found with service status.  Restarting service."
    Restart-Service $AcctService
    Send-MailMessage -To "email@email.com" -Subject "INFORMATIONAL - Investigate Issue - $env:COMPUTERNAME CitrixADIdentityService not responding" -SmtpServer "smtp3dns.bankofamerica.com" -port 25 -From "gmrt_citrix_reports@bofa.com" -body "INFORMATIONAL - Investigate Issue - $env:COMPUTERNAME CitrixADIdentityService service restarting due to start not equal to 'OK'. Check $env:COMPUTERNAME for event details to determine root cause for failed service." -BodyAsHTML
    }
Else
{
    Write-Output   "Citrix Acct Service Status OK"
    }

# Check "Citrix Analytics" service status with Database
$AnalyticsService = 'CitrixAnalytics'
$AnalyticsServiceStatus = Get-AnalyticsServiceStatus
