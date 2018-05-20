<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
	 Created on:   	10/3/2017 2:34 PM
	 Created by:   	bpeppin, @brookspeppin, brookspeppin.com
     Updated: Bpeppin, 10/30/17     	
	===========================================================================
	.DESCRIPTION
		Airwatch Dynamic Silent Enrollment using Airwatch APIs
#>

#Variable Section-------------------------------------------------------------------------------
$version = 'v9'
$serverlogpath = "\\serverunclogpath\AirwatchEnrollment\$version" #UNC path for server log
$user = "servername\sccmlogs" #log server local account name 
$pass = "T0pS3cret" | ConvertTo-SecureString -AsPlainText -Force #log server password
$locallogpath = "C:\Corp_IT\Logs\AirwatchEnrollment" #local path for logs
$localfilename = "$env:computername-$version.log" #local log file name
$URL = "https://yourserver.awmdm.com/api" #Airwatch API server
$cred_server = "\\servername\Share$" #server where api credentials are stored, recommend you make it a hidden share
$APIkey = "API.txt" #AW API Key stored in this txt file. Q: is $cred_server
$cred = "something.txt" #AW admin base64 encoded username:password stored in this text file. Q: is $cred_server
$LocationGroupID = "yourgroupIDnumber" #this is the locationgroupID of your primary enrollment OG. (Integer)
#-----------------------------------------------------------------------------------------------

Start-Transcript $locallogpath\$localfilename
Write-Host "Script version is: $version"
#Ensuring log locations exist
If ((Test-Path $locallogpath) -eq $false)
{
	md $locallogpath
}
If ((Test-Path $serverlogpath) -eq $false)
{
	md $serverlogpath
}

#Checking first for Airwatch Enrollment
$PATH = "HKLM:SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
$val = (Get-ItemProperty -Path $PATH -ErrorAction SilentlyContinue).PSChildname

#Now checking whether enrollment is with a real user or the staging user
$path2 = "HKLM:\SOFTWARE\Microsoft\Enrollments\$val"
$val2 = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).UPN
if ($val2 -eq "StagingWin10@Staging.com" -or $val2 -eq "staging@aw.com" -or $val2 -eq $null)
{
	$serial = (gwmi win32_BIOS).SerialNumber
	Write-host "Non-Compliant Enrollment, enrolled as $val2, Serial = $serial"
	Write-host "Checking for existing Airwatch install..."
	$uninstallString64 = (Get-ItemProperty HKLM:\Software\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\* | where-Object { $_.DisplayName -like "Airwatch*" }).PSChildName
	$uninstallString32 = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where-Object { $_.DisplayName -like "Airwatch*" }).PSChildName
	if ($uninstallString64)
	{
		try
		{
			Write-host "$uninstallString64 GUID found"
			Write-host "Uninstalling 64bit AirwatchAgent..."
			start-process -Wait "msiexec" -arg "/X $uninstallString64 /qn"
		}
		catch
		{
			Write-host $_.Exception
			Write-host "Issues with uninstalling 64bit airwatch agent"
		}
		
	}
	if ($uninstallString32)
	{
		try
		{
			Write-host "$uninstallString32 GUID found"
			Write-host "Uninstalling 32bit AirwatchAgent..."
			start-process -Wait "msiexec" -arg "/X $uninstallString32 /qn"
		}
		catch
		{
			Write-host $_.Exception
			Write-host "Issues with uninstalling 64bit airwatch agent"
		}
		
	}
	
	#Getting API Credentials from local share - maps to "Q" drive
	try
	{
		$credential = New-Object System.Management.Automation.PsCredential($user, $pass)
		new-psdrive -name Q -PsProvider FileSystem -root $cred_server -Credential $credential | out-default
	}
	catch
	{
		Write-host $_.Exception
	}
		
	#main REST HEADER
	$APIkey = Get-Content "Q:\$APIkey"
	$cred = Get-Content "Q:\$cred"
	$header = @{
		"Authorization"  = "Basic $cred";
		"aw-tenant-code" = $APIkey;
		"Accept"		 = "application/json";
		"Content-Type"   = "application/json";
	}
	
	#Delete device from console as the enrollment is most likely broken
	Try
	{
		Write-host "Deleting device from console"
		$apipath = '/mdm/devices?searchBy=Serialnumber&id='
		Invoke-RestMethod -Uri "$URL$apipath$serial" -Method "DELETE" -Headers $header

	}
	catch
	{
		Write-host $_.Exception
		Write-host "Issues deleting device or device doesn't exist."
		Write-host "ErrorMessage:" $_.Exception.Message
		Write-host "ErrorStatus:" $_.Exception.Status
	}
	
	#Checking for existing Registration Token
	Write-host "Checking for existing Registration Token"
	$apipath = "/system/users/enrollmenttoken/search?serialnumber="
	$registration = Invoke-RestMethod -Uri "$URL$apipath$serial" -Headers $header
	#create new registration if no registration exists
	If ($registration -eq "")
	{
		#Gets userID number as the API requires it
		$apipath = "/system/users/search?username=$env:username"
		$userid = (Invoke-RestMethod -Uri "$URL$apipath" -Headers $header).Users
		$userid = ($userid | where { ($_.username -like "$env:username") -and ($_.group -notlike "staging") }).ID.Value #ensures its a real acccount
		#creating new registration record
		$apipath = "/system/users/$userid/registerdevice"
		$body = @{
			'LocationGroupID' = "$LocationGroupID" #enroll into Production OG
			'FriendlyName'    = "$env:username";
			'Ownership'	      = 'C'; #company owned
			'SerialNumber'    = "$serial";
			'PlatformID'	  = '12'; #Windows Desktop platform ID
			
		}
		$json = $body | ConvertTo-Json
		Try
		{
			Write-host "No device registration found. Creating new."
			Invoke-RestMethod -Uri "$URL$apipath" -Method POST -Headers $header -Body $json
		}
		catch
		{
			Write-host $_.Exception
			Write-host "ErrorMessage:" $_.Exception.Message
			Write-host "ErrorStatus:" $_.Exception.Status
		}
	}
	else
	{
		Write-host "Device registration already exists."
	}
	
	
	Write-host "Installing Device Managment Compatibility Tool	..."
	Start-Process msiexec.exe -Wait -ArgumentList '/I installer-1.0.0.55-x64.msi /qn'
	
	Write-host "Installing Airwatch Agent..."
	Write-host "Enrolling $env:USERNAME with Serial = $serial"
	Try
	{
		Start-Process msiexec.exe -Wait -ArgumentList "/i AirwatchAgent.msi /quiet ENROLL=Y IMAGE=N SERVER=yourserver.awmdm.com LGName=Staging USERNAME=StagingWin10 PASSWORD=Win10 /log $locallogpath\AWAgent.log"
	}
	catch
	{
		Write-host $_.Exception
	}
	Write-host "Waiting 60 seconds for AW enrollment to complete..."
	start-sleep 60
	Write-host "Validating Enrollment..."
	$PATH = "HKLM:SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
	$val = (Get-ItemProperty -Path $PATH -ErrorAction SilentlyContinue).PSChildname
		#Now checking whether enrollment is with a real user or the staging user
	$path2 = "HKLM:\SOFTWARE\Microsoft\Enrollments\$val"
	$val2 = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).UPN
	if ($val2 -eq "StagingWin10@Staging.com" -or $val2 -eq "staging@aw.com" -or $val2 -eq $null)
	{
		Write-host "Enrollment Failed. Sending failure email."
		Stop-Transcript
		$EmailFrom = "emailaddress"
		$EmailTo = "emailaddress"
		$CC = "emailaddress"
		$SmtpServer = "smtp email server"
		$date = Get-Date
		
		$message = @{
			Subject	    = "Airwatch Enrollment Failed - $env:computername"
			Body	    = "ComputerName: $env:computername<br>Username: $env:USERNAME<br>Serial: $serial<br>Logs attached. Full log also located at $serverlogpath\$env:computername<br>"
			From	    = "$EmailFrom"
			To		    = "$EmailTo"
			CC			= "$CC"
			SmtpServer  = "$SmtpServer"
		}
		
		Write-host "Sending e-mail of logs"
		
		Send-MailMessage @message -BodyAsHtml -Attachments $locallogpath\$localfilename, "$locallogpath\AWAgent.log"
	}
	else
	{
		Write-host "Success Enrollment validated"
		Stop-Transcript
		$EmailFrom = "emailaddress"
		$EmailTo = "emailaddress"
		$CC = "emailaddress"
		$SmtpServer = "smtp email server"
		$date = Get-Date
		
		$message = @{
			Subject	    = "Airwatch Enrollment Success! - $env:computername"
			Body	    = "ComputerName: $env:computername<br>Username: $env:USERNAME<br>Serial: $serial<br>Logs attached. Full log also located at $serverlogpath\$env:computername<br>"
			From	    = "$EmailFrom"
			To		    = "$EmailTo"
			CC		    = "$CC"
			SmtpServer  = "$SmtpServer"
		}
		
		Write-host "Sending e-mail of logs"
		
		Send-MailMessage @message -BodyAsHtml -Attachments $locallogpath\$localfilename, "$locallogpath\AWAgent.log"
	}
}
Else
{
	$status = "Enrolled"
	Write-host "Compliant. Successfully enrolled as $val2"
}

#mapping log server to copy logs
Try
{
	$credential = New-Object System.Management.Automation.PsCredential($user, $pass)
	New-PSDrive -Name UNCPath -PSProvider FileSystem -Root $serverlogpath -Credential $credential
}
catch
{
	Write-host $_.Exception
}
Write-Host "Copying log..."
Copy-Item "$locallogpath\$localfilename" UNCPath -force 