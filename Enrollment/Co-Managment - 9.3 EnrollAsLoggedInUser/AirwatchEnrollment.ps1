<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
	 Created on:   	10/3/2017 2:34 PM
	 Created by:   	bpeppin, brookspeppin.com, @brookspeppin
     Updated:		Bpeppin, 3/27/18
	 Organization: 	VMware, Inc.
	 Filename:     	AirwatchEnrollment.ps1
	===========================================================================
	.DESCRIPTION
		Airwatch Silent Enrollment with SCCM with new 9.3 agent enhancements:
			- new switch ASSIGNTOLOGGEDINUSER=Y
			- Falls back to prompt for username and password if the assigntologgedinuser fails
		
	.NOTES
		Requires Airwatch agent and console version 9.3 or higher
		Requires that this be run as the logged on user context who has local admin rights.

    .USAGE
        Deploy manually or with sccm using command line:
        powershell -executionpolicy bypass -file AirwatchEnrollment.ps1
        More command line switch details at: https://my.air-watch.com/help/9.3/en/Content/Platform_Guides/WinDesktop/R/Enroll_SilentCommands.htm
#>

#Variable Section
$version = 'vxx'
#$serverlogpath = "[path]\$version" #UNC path for server log
#$user = "[account]" #log server account name 
#$pass = "[password]" | ConvertTo-SecureString -AsPlainText -Force #log server password
$scriptlogpath = "C:\Temp\Logs\AirwatchEnrollment" #local path for logs
$scriptfilename = "$env:computername-$version.log" #local log file name
$DeviceOwnershipType = "CS" #device ownership type
$SERVER = "cnxxx.awmdm.com" #enrollment server
$LGName = "Staging" #Organization group name of the staging OG
$USERNAME = "StagingWin10" #staging account username
$PASSWORD = "Win10" #staging account password
$AWAGENTLOGPATH = "C:\Temp\Logs\AirwatchEnrollment\"
#Ensuring log locations exist
If ((Test-Path $scriptlogpath) -eq $false)
{
	md $scriptlogpath
}
If ((Test-Path $serverlogpath) -eq $false)
{
	md $serverlogpath
}
If ((Test-Path $AWAGENTLOG) -eq $false)
{
	md $AWAGENTLOG
}
Start-Transcript $scriptlogpath\$scriptfilename
Write-Host "Script version is: $version"


#Checking first for Airwatch Enrollment
$PATH = "HKLM:SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
$val = (Get-ItemProperty -Path $PATH -ErrorAction SilentlyContinue).PSChildname

#Now checking whether enrollment is with a real user or the staging user
$path2 = "HKLM:\SOFTWARE\Microsoft\Enrollments\$val"
$val2 = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).UPN #This returns the email address of enrolled user
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
	
	
	Write-host "Installing Device Managment Compatibility Tool	..."
	Start-Process msiexec.exe -Wait -ArgumentList '/I installer-1.0.0.55-x64.msi /qn'
	
	Write-host "Installing Airwatch Agent..."
	Write-host "Enrolling $env:USERNAME with Serial = $serial"
	Try
	{
		Start-Process msiexec.exe -Wait -ArgumentList "/i AirwatchAgent.msi /quiet ENROLL=Y IMAGE=N SERVER=$SERVER LGNAME=$LGName USERNAME=$USERNAME PASSWORD=$PASSWORD ASSIGNTOLOGGEDINUSER=Y /log $AWAGENTLOGPATH\AWAgent.log"
	}
	catch
	{
		Write-host $_.Exception
	}
	Write-host "Waiting 10 min for AW enrollment to complete..."
	start-sleep 600
	Write-host "Validating Enrollment..."
	
	#Checking first for Airwatch Enrollment
	$PATH = "HKLM:SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
	$val = (Get-ItemProperty -Path $PATH -ErrorAction SilentlyContinue).PSChildname
	
	#Now checking whether enrollment is with a real user or the staging user
	$path2 = "HKLM:\SOFTWARE\Microsoft\Enrollments\$val"
	$val2 = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).UPN
	if ($val2 -eq "StagingWin10@Staging.com" -or $val2 -eq "staging@aw.com" -or $val2 -eq $null)
	{
		Write-host "Enrollment Failed. Sending failure email."
		Write-host "Non-Compliant Enrollment, enrolled as $val2, Serial = $serial"
	}
	else
	{
		Write-Host "Airwatch enrollment Successful."
		Write-Host "Airwatch enrollment Successful. Enrolled as $val2, Serial = $serial"
		
	}
	<#if ($val2 -eq "StagingWin10@Staging.com" -or $val2 -eq "staging@aw.com" -or $val2 -eq $null)
	{
		Write-host "Enrollment Failed. Sending failure email."
		Write-host "Non-Compliant Enrollment, enrolled as $val2, Serial = $serial"
		Stop-Transcript
		$EmailFrom = "[email here]"
		$EmailTo = "[email here]"
		$CC = "[email here]"
		$SmtpServer = "[smtp server here]"
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
		
		Send-MailMessage @message -BodyAsHtml -Attachments $locallogpath\$localfilename, "$locallogpath\AWAgent.log", "C:\ProgramData\Airwatch\UnifiedAgent\Logs\NativeEnrollment.log"
	}
	else
	{
		Write-host "Success Enrollment validated"
		Stop-Transcript
		$EmailFrom = "[email here]"
		$EmailTo = "[email here]"
		$CC = "[email here]"
		$SmtpServer = "[smtp server here]"
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
		
		Send-MailMessage @message -BodyAsHtml -Attachments $locallogpath\$localfilename, "$locallogpath\AWAgent.log", "C:\ProgramData\Airwatch\UnifiedAgent\Logs\NativeEnrollment.log"
	}#>
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
xcopy "$locallogpath\$localfilename" "$serverlogpath\$env:COMPUTERNAME\" /f /y
xcopy "$locallogpath\AWAgent.log" "$serverlogpath\$env:COMPUTERNAME\" /f /y
xcopy "C:\ProgramData\Airwatch\UnifiedAgent\Logs\NativeEnrollment.log" "$serverlogpath\$env:COMPUTERNAME\" /f /y
