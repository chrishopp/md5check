<#Powershell file to verify FTP files (mp2 wav files) from PRX by md5 check in a local folder and note discrepancies
script could be modified to check any file type on line 11

Run in Powershell or start from a cmd/bat file (bat/cmd file can't run for UNC file paths):
line for cmd to run: Powershell -executionpolicy bypass -file verifymd5.ps1 | more

-Chris Hopp 08-27-2018
same folder version
#>
#specify file types to check in array format i.e. = "*.wav","*.mp3"
$filestocheck = "*.wav"

#set initial paths/values
echo "Processing, please wait..."
$currentfolder = Get-Location
$now = get-date -Uformat %Y-%m-%d-%I%M%p
$md5s = "*.md5"

#check for log folder, create if doesn't exist
$logfolder = "$currentfolder\md5logs"
If(!(test-path $logfolder)){
	New-Item -ItemType Directory -Force -Path $logfolder
	}

#get file hashes and md5 file contents and store in array for comparison 
$fileresults = Get-Filehash $filestocheck -algorithm md5 | select -expandproperty hash
$md5results = @( foreach ($file in $md5s) {
Get-Content $md5s
	})
	
#compare files to md5 files, store results
$compareresults = Compare-Object $fileresults $md5results -passthru | Out-File "$logfolder\compareresults.txt"
Add-Content "$logfolder\warningfile.txt" ""
Clear-Content "$logfolder\warningfile.txt"
foreach ($line in Get-Content "$logfolder\compareresults.txt"){
Get-ChildItem $filestocheck | Get-FileHash -Algorithm md5 | Where-Object hash -eq $line | Select path | Add-Content "$logfolder\warningfile.txt"
	}

#add date/time and path file history file for future reference
Add-Content "$logfolder\file_error_history.txt" "md5 check run at $now"

#check for errors, report results
$errorsexist = Get-Content "$logfolder\compareresults.txt"
if($errorsexist){
echo "`n warning, the following files contain differences from the md5 values `n"
$errors = Get-Content "$logfolder\warningfile.txt"
echo $errors
Add-Content "$logfolder\file_error_history.txt" "The following files contained md5 mismatches: `n $errors"
echo "`n see file warningfile.txt or file_error_history.txt in logs folder for reference `n"
	}
else {
echo "`n md5 values match for files in folder, there are no discrepancies `n"
Add-Content "$logfolder\file_error_history.txt" "There were no md5 mismatches."
	}
Read-Host -Prompt "Press Enter to exit"