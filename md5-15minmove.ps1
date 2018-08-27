<#powershell file to check for files older than 15 minutes and move into hourold folder for further processing
waiting until files in FTP are at least 15 minutes old helps ensure files have completed download

line for cmd to test: Powershell -executionpolicy bypass -file md5-15minmove.ps1" | more
-Chris Hopp 12-08-2017
#>

#modify paths as needed
$logsfolder = Get-Location
$FTPUNCpath = kvnoFTP.edu #assumes FTP path mapped on local computer, could also be drive letter mapping of FTP
Start-Transcript -Path "$logsfolder\powershelllog.txt" -NoClobber -Append
$pathtonew = "\\$FTPUNCpath\PRX\" #path to root PRX FTP share
$pathtosource = "\\$FTPUNCpath\PRX\hourold\" #path to PRX FTP share after move of hour old
$fifteeninpast = (get-date).addminutes(-15) #set var 15 minutes in past
$now = get-date -Uformat %Y-%m-%d-%I%M%p

#move files at least 15 minutes old to hourold folder for further processing
Get-ChildItem -Path "$pathtonew\*.wav" | where-object {$_.creationtime -lt $fifteeninpast} | move-item -Destination $pathtosource
Get-ChildItem -Path "$pathtonew\*.md5" | where-object {$_.creationtime -lt $fifteeninpast} | move-item -Destination $pathtosource

Stop-Transcript