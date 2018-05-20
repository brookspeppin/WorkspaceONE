<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018
	 Created on:   	10/3/2017 2:34 PM
	 Created by:   	Brooks Peppin, @brookspeppin, brookspeppin.com
     Updated:		Bpeppin, 3/23/18
	 Organization: 	VMware, Inc.
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Airwatch Silent Enrollment with SCCM
		
	.NOTES
		Requires Airwatch 9.3 or higher
		Requires that this be run as the logged on user context who has local admin rights.
		Please enable user group mapping so that the device is automatically moved to the correct Organization Group. If not,
		the user will see a popup asking to enter GroupID.

    .USAGE
        Deploy manually or with sccm using command line: powershell -executionpolicy bypass -file AirwatchEnrollment.ps1
        More command line switch details on the AirWatch agent at: 
		https://my.air-watch.com/help/9.3/en/Content/Platform_Guides/WinDesktop/R/Enroll_SilentCommands.htm
#>

#Variable Section
$version = 'vxx'
#Un-comment these if you want to send logs to central server
#$serverlogpath = "\\logserver\AirwatchEnrollment\$version" #UNC path for server log
#$user = "logserver\sccmlogs" #log server local account name 
#$pass = "password" | ConvertTo-SecureString -AsPlainText -Force #log server password
$scriptlogpath = "C:\VMware_IT\Logs\AirwatchEnrollment" #local path for logs
$scriptfilename = "$env:computername-$version.log" #local log file name
$SERVER = "cnxxx.awmdm.com"
$DeviceOwnershipType = "CD" #'CD' for Corporate Dedicated,'CS' for Corporate Shared, 'EO' for Employee Owned, 'N' for None.
$LGName = "Staging" #Organization group name where staging account is located (needs to be "sibling" OG if SAML is enabled on primary OG
$USERNAME="StagingWin10" #staging account username
$PASSWORD="Win10" #staging account password
$AWAGENTLOGPATH="C:\VMware_IT\Logs\AirwatchEnrollment\"
#Ensuring log locations exist
If ((Test-Path $scriptlogpath) -eq $false)
{
	md $scriptlogpath
}
If ((Test-Path $serverlogpath) -eq $false)
{
	md $serverlogpath
}
If ((Test-Path $AWAGENTLOGPATH) -eq $false)
{
	md $AWAGENTLOGPATH
}
Start-Transcript $scriptlogpath\$scriptfilename
Write-Host "Script version is: $version"


#Checking first for Airwatch Enrollment
$PATH = "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
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
		Start-Process msiexec.exe -Wait -ArgumentList "/i AirwatchAgent.msi /quiet ENROLL=Y IMAGE=N SERVER=$SERVER LGNAME=$LGName USERNAME=$USERNAME PASSWORD=$PASSWORD DEVICEOWNERSHIPTYPE=$DeviceOwnershipType /log $AWAGENTLOGPATH\AWAgent.log"
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
