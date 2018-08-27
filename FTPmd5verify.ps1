<#powershell file to verify FTP files by md5 and notify by email if descrepancies exist
after md5 check, kickoff move files older than 1 hour
not transfering files newer than 1 hour helps ensure file has finished downloading

line for cmd to test: Powershell -executionpolicy bypass -file FTPmd5verify.ps1 | more
-Chris Hopp 10-31-2017
#>
$FTPUNCpath = kvnoFTP.edu #assumes FTP path mapped on local computer, could also be drive letter mapping of FTP
$automationsystemingest = ingest.edu
Start-Transcript -Path "\\$FTPUNCpath\errors\powershelllog.txt" -NoClobber -Append
$pathtonew = "\\$FTPUNCpath\PRX\" #path to root PRX FTP share
$pathtosource = "\\$FTPUNCpath\PRX\hourold\" #path to PRX FTP share after move of hour old
$pathtotarget = "\\$automationsystemingest\Audio\nexgen\Import\" #path to Nexgen import folder
$pathtoerrors = "\\$FTPUNCpath\errors" #path to error notes folder
$onehourinpast = (get-date).addhours(-1) #set var 1 hour in the past
$now = get-date -Uformat %Y-%m-%d-%I%M%p

#move files at least an hour old to hourold folder for further processing
Get-ChildItem -Path "$pathtonew\*.wav" | where-object {$_.creationtime -lt $onehourinpast} | move-item -Destination $pathtosource
Get-ChildItem -Path "$pathtonew\*.md5" | where-object {$_.creationtime -lt $onehourinpast} | move-item -Destination $pathtosource

#define file types for md5 checks, as of 10-30-17 only PRX files are processed with  md5 values so limited to wav
$allfiles = "$pathtosource*"
$files= "$pathtosource*.wav"
$md5s = "$pathtosource*.md5"

#get wav file hashes and get md5 file contents and store in array for comparison 
$md5results = @( foreach ($file in $files) {
Get-Filehash $files -algorithm md5 | select -expandproperty hash
	})
$fileresults = @( foreach ($file in $md5s) {
Get-Content $md5s
	})

#compare compare files to md5 files, store results
$compareresults = Compare-Object $fileresults $md5results -passthru | Out-File "$pathtoerrors\compareresults.txt"

Add-Content "$pathtoerrors\warningfile.txt" ""
Clear-Content "$pathtoerrors\warningfile.txt"
foreach ($line in Get-Content "$pathtoerrors\compareresults.txt"){
Get-ChildItem $allfiles | Get-FileHash -Algorithm md5 | Where-Object hash -eq $line | Select path | Add-Content "$pathtoerrors\warningfile.txt"
}

#add date/time and path file history file for future reference
$now | Add-Content "$pathtoerrors\file_error_history.txt"
Get-Content "$pathtoerrors\warningfile.txt" | Add-Content "$pathtoerrors\file_error_history.txt"

#if errors exist, email errors, move files to import folder regardless of errors
$errorsexist = Get-Content "$pathtoerrors\compareresults.txt"
if($errorsexist){
echo "warning, there are differences"

$from = "from@unomaha.edu"
$to = @("to@unomaha.edu", "to@unomaha.edu")
$subject = "FTP md5 errors found"
$body = "This is an automated message from _______. Please check the file list atached. Items in this list may not have loaded or arrived correctly. Their md5 values don't match what was sent."
$attachment = "$pathtoerrors\warningfile.txt"
$smtpserver = "smtpserver.edu"
Send-MailMessage -From $from -to $to -Subject $subject -Attachments $attachment -Body $body -SmtpServer $smtpserver #-Credential (Get-Credential)
#>
}
else{
echo "success, the results match, there are no differences"
}

#copy promos to promodrop folder, copy CSO files to CSO2, move all wav files older than 1 hour to Nexgen Import folder, remove md5 files
Copy-Item -Path "$pathtosource*ChicagoS_*_SGMT*" -Destination "\\$automationsystemingest\Audio\AFCLauncher\CSO2"
Copy-Item -Path "$pathtosource*_PROM*" -Destination "\\$FTPUNCpath\Production\promos\PromoDrop"
Copy-Item -Path "$pathtosource*30320.wav" -Destination "\\$FTPUNCpath\Production\promos\PromoDrop\RelevantTonesPromo-transferred-$now.wav"
get-childitem -path "$pathtosource*.wav" | where-object {$_.creationtime -lt $onehourinpast} | move-item -destination $pathtotarget
get-childitem -path "$pathtosource*.md5" | where-object {$_.creationtime -lt $onehourinpast} | remove-item

Stop-Transcript