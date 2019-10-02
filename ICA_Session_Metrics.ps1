<#

Authors: Eugene Sackman, Thomas Mshar
Version: 0.1.8
Date: 08\07\2018
Purpose: Grab ICA Channel specific metrics from the client and log locally. Script does not require administrative rights to run.

*** Depending on how many users are attached to the TS, it may take a few moments to spool up the data.

Notes:
[0.1.7] TM changed formatting & added client ip to the output
[0.1.6] TM added severalnew counters including citrix directory, domain\user, monitor resolution, application launched, client address, geteway used, gateway tags, clientname
[0.1.4] TM added OutputSessionBandwidth in an effort to display how much data within the channel is being consumed. 
[0.1.3] TM changed output format, added raw counters in the event we wanted to log later, translated OutputSessionLineSpeed to Kbps for lower than expected counters
[0.1.2] TM added [$env:username] to $logpath to prevent log file collision w/ multple instances running at the same time

Counters: 
(bps) Output Session Line Speed: The line speed, measured in bps, used from server to client for a session
(bps) Output Session Bandwidth: The bandwidth, measured in bps, used from server to client for a session. 
(ms ) Latency - Last Recorded: The last recorded latency measurement for the session
(ms ) Latency - Session Average: The average client latency over the lifetime of a session. 
(ms ) Latency - Session Deviation: The difference between the minimum and maximum measured latency values for a session. 
(bps) Output ThinWire Bandwidth: The bandwidth, measured in bps, used from server to client for ThinWire traffic. 
(bps) Input Seamless Bandwidth: The bandwidth, measured in bps, used for published applications that are not embedded in a session window.
(bps) Input Session Line Speed: The line speed, measured in bps, used from client to server for a session. 
(bps) Output Seamless Bandwidth: The bandwidth, measured in bps, used for published applications that are not embedded in a session window

#>

begin {


$ErrorActionPreference = 'silentlycontinue' 
$myVersion = '0.1.8'
$int_logpath = "C:\temp\bench\logs\session"
If(!(test-path $int_logpath)){New-Item -ItemType Directory -Force -Path $int_logpath}
[string]$date = get-date -Format MM-dd-yyyy-hh:mmtt

$pswindow=$pshost.ui.rawui
$new_window_size=$pswindow.windowsize
$new_buffer_size=$pswindow.buffersize
$new_window_size.Height=100
$new_window_size.Width=3000
$new_buffer_size.Height=1200
$new_buffer_size.Width=1500
$pswindow.BufferSize=$new_buffer_size
$pswindow.WindowSize=$new_window_size

$one = 1
$two = 2
[int]$sleepinterval = 15
$pswindow.WindowTitle="WSS ICA Metrics [Version: $myVersion] LogPath: c:\temp\bench\logs\($env:username)$env:computername-SessionMetrics.csv"
$logPath="c:\temp\bench\logs\($env:username)$env:computername-SessionMetrics.csv"

"Date_Time,Version,Session,Latency Last Recorded, Latency Session Average,Latency Session Deviation,"`
+ "Output Session Line Speed (Mbps),Output Session Bandwidth (Kbps),Output ThinWire Bandwidth (Kbps),"`
+ "Input ThinWire Bandwidth (Kbps),Input Seamless Bandwidth,Input Session Line Speed,Output Seamless Bandwidth,"`
+ "CitrixDir,Domain_User,Mon_Resolution,AppLaunched,ClientVersion,ClientAddress,AccessGatewayFarm,AccessGatewayTags,clientname" | out-file -FilePath $logpath -encoding utf8

clear-host

}


process {

do

{

#===============================
$myhash.Clear()
$registry = get-childitem "HKLM:\SOFTWARE\Citrix\Ica\Session\" -recurse
$myHash = @{}
#$myhash.add($key,$value)


foreach ($a in $registry) {
    $a.property | ForEach-Object {

if ($_ -eq "UserName") {
 
    $sessionID = ($a.PSParentPath + "\" + $a.PSChildName)
    $test = Get-ItemProperty -path $sessionID
    #write-host ($test.DomainName + "\" + $test.UserName + " connected via " + $test.agfarm)
    #enter value into hash table if not exist

if($myHash.containsKey($test.username)){
 
    #write-host ("Key found for " + $test.UserName + ", do nothing")

}else{

    $mon_res=([string]$test.HRes + "x" + [string]$test.VRes) 
    $cli_dir=([string]$test.ClientDirectory)
    $my_string=($cli_dir + "^" + ($test.DomainName + "\" + $test.username) + "^" + ($mon_res + "^" + $test.PublishedName + "^" + $test.ClientVersion  + "^" + $test.ClientName + "^" + $test.ClientAddress + "^" + $test.agfarm + "^" + $test.agtags + "^" + $test.clientname))
    $myhash.add($test.UserName,$my_string)
}
}}}

$raw_ica_counter = Get-WmiObject Win32_PerfRawData_CitrixICA_ICASession
foreach ($ica_counter in $raw_ica_counter)
{
    
    $ses = $ica_counter.Name
    $1,$2,$3 = $ses.split("(")
    $cur_name = $2.split(")") #extract username from avail. data 
    $lrr = $ica_counter.LatencyLastRecorded
    $lsa = $ica_counter.LatencySessionAverage
    $lsd = $ica_counter.LatencySessionDeviation
    $osl = [math]::Round([int]$ica_counter.OutputSessionLineSpeed  / 1mb, 2).tostring("#.00")
    $osl_raw = $ica_counter.OutputSessionLineSpeed
    $osl_raw_kbps = [math]::Round([int]$ica_counter.OutputSessionLineSpeed * 0.0009765625, 2).tostring("#.00")
    $osb = [math]::Round([int]$ica_counter.OutputSessionBandwidth * 0.0009765625, 2).tostring("#.00")
    $osb_raw = $ica_counter.OutputSessionBandwidth
    $otb = [math]::Round([int]$ica_counter.OutputThinwireBandwidth * 0.0009765625, 2).tostring("#.00")
    $otb_raw = $ica_counter.OutputThinwireBandwidth
    $itb = [math]::Round([int]$ica_counter.InputSessionBandwidth * 0.0009765625, 2).tostring("#.00")
    $isb = $ica_counter.InputSeamlessBandwidth
    $isls = $ica_counter.InputSessionLineSpeed
    $osbw = $ica_counter.OutputSeamlessBandwidth


    foreach ($key in $myHash.keys)
    {
    if ($cur_name -match $key){ 
    #write-host "found match! " $key " with " $cur_name "-----" $myHash[$key]
    $dir,$user,$res,$publishedName,$clientVersion,$clientName,$clientAddress,$agfarm,$agtags,$clientname=$myhash[$key].split("^")
    }
    }

#"CitrixDir,Domain_User,Mon_Resolution,AppLaunched,ClientVersion,ClientAddress,AccessGatewayFarm,AccessGatewayTags"           
$lines = ""
$lines += [String][System.DateTime]::Now + "," + $myVersion + "," + $ses + "," + $lrr + "," + $lsa + "," + $lsd + "," + $osl + "," + $osb + "," + $otb + "," + $itb + "," +
$isb + "," + $isls + "," + $osbw + "," + $dir + "," + $user + "," + $res + "," + $publishedName + "," + $clientVersion + "," + $clientAddress + "," + $agfarm + "," + $agtags + "," + $clientName

$Lines | Out-File -FilePath $logPath -Encoding utf8 -Append

[double]$n_osl = $osl
[int]$n_lrr = $lrr
[string]$monitor_res = $res

if($ses -eq "_Server total"){
} else {
write-host $(get-date).tostring().PadRight(23) -ForegroundColor DarkGray -NoNewline
#Write-host $ses.tostring().padleft(32) -foregroundcolor darkCyan -NoNewline
Write-host $user.tostring().padleft(8) -foregroundcolor darkCyan -NoNewline

write-host " [Mon.Res] " -ForegroundColor DarkGray -nonewline
write-host $monitor_res.PadLeft(9) -ForegroundColor DarkCyan -NoNewline

write-host " [AGUsed?] " -ForegroundColor DarkGray -nonewline
write-host $agfarm.PadLeft(20) -ForegroundColor DarkCyan -NoNewline

Write-host " [SessionLatency] " -ForegroundColor DarkGray -NoNewline
if($n_lrr -gt 500){
write-host $lrr.tostring("00").padleft(5) -foregroundcolor red -nonewline
} else { 
write-host $lrr.tostring("00").padleft(5) -foregroundcolor darkCyan -nonewline
}

write-host " [OutputSessionLineSpeed] " -ForegroundColor DarkGray -nonewline
if($n_osl -lt 1.5){
write-host "(Mbps)" -ForegroundColor Darkgray -nonewline
write-host $osl.tostring().padleft(7) -ForegroundColor red -NoNewline
write-host " (Kbps)" -ForegroundColor Darkgray -nonewline
write-host $osl_raw_kbps.tostring().padleft(10) -ForegroundColor darkcyan -nonewline
write-host " (bps)" -ForegroundColor Darkgray -nonewline
write-host $osl_raw.tostring().padleft(10) -ForegroundColor darkcyan -nonewline
write-host " | Used (Kbps)" -ForegroundColor Darkgray -nonewline
write-host $osb.tostring().padleft(7) -ForegroundColor darkcyan -NoNewline

} else {
write-host "(Mbps)" -ForegroundColor Darkgray -nonewline
write-host $osl.tostring().padleft(7) -ForegroundColor darkCyan -NoNewline
write-host " (Kbps)" -ForegroundColor Darkgray -nonewline
write-host $osl_raw_kbps.tostring().padleft(10) -ForegroundColor DarkCyan -NoNewline
write-host " (bps)" -ForegroundColor Darkgray -nonewline
write-host $osl_raw.tostring().padleft(10) -ForegroundColor darkcyan -NoNewline
write-host " | Used (Kbps)" -ForegroundColor Darkgray -nonewline
write-host $osb.tostring().padleft(7) -ForegroundColor darkcyan -NoNewline
}

write-host " [AppName] " -ForegroundColor DarkGray -nonewline
write-host $publishedName.PadLeft(30) -ForegroundColor DarkCyan -NoNewline

write-host " [ClientVersion] " -ForegroundColor DarkGray -nonewline
write-host $clientVersion.PadLeft(12) -ForegroundColor DarkCyan -NoNewline

write-host " [ClientName] " -ForegroundColor DarkGray -nonewline
write-host $clientAddress.PadLeft(15) -ForegroundColor DarkCyan -NoNewline
write-host " | " -ForegroundColor DarkGray -nonewline
write-host $clientName.padright(2) -ForegroundColor DarkCyan


#$myhash.Clear()


}
}
start-sleep $sleepinterval
}
while ($one -ne $two)
}
end { } 
