<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
	 Created on:   	1/26/2018 3:38 PM
	 Created by:   	bpeppin
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Enrolls a device into AirWatch as a login script. Runs as the logged in user creds and thus requires the following:
		- User must be a local admin
		- Requires device pre-registration in AW console (generally done during imaging)
#>
$version = 'vxx'
#Un-comment these if you want to send logs to central server
#$serverlogpath = "\\logserver\AirwatchEnrollment\$version" #UNC path for server log
#$user = "logserver\sccmlogs" #log server local account name 
#$pass = "password" | ConvertTo-SecureString -AsPlainText -Force #log server password
$scriptlogpath = "C:\VMware_IT\Logs\AirwatchEnrollment" #local path for logs
$scriptfilename = "AWEnrollment-$version.log" #local log file name
$SERVER="cnxxx.awmdm.com"
$LGName="Staging" #Organization group name where staging account is located (needs to be "sibling" OG if SAML is enabled on primary OG
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
$whoami = whoami
if ($whoami -match "administrator")
{
	Write-Host "$whoami detected, exiting..."
	exit 0
}
Write-Host $whoami
Write-Host "Checking for Airwatch Enrollment"
$PATH = "HKLM:SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*"
$val = (Get-ItemProperty -Path $PATH -ErrorAction SilentlyContinue).PSChildname

Write-Host "Now checking whether enrollment is with a real user or the staging user"
$path2 = "HKLM:\SOFTWARE\Microsoft\Enrollments\$val"
$val2 = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).UPN
Write-Host "UPN=$val2"
if ($val2 -eq "StagingWin10@Staging.com" -or $val2 -eq "staging@aw.com" -or $val2 -eq $null)
{
	
	Try
	{
		Write-Host "Attempting to enroll system into AirWatch."
		Start-Process msiexec.exe -Wait -ArgumentList "/i AirwatchAgent.msi /quiet ENROLL=Y IMAGE=N SERVER=$SERVER LGNAME=$LGName USERNAME=$USERNAME PASSWORD=$PASSWORD /log $AWAGENTLOGPATH\AWAgent.log"
	}
	catch
	{
		Write-host $_.Exception
	}
}
else
{
	Write-Host "Valid enrollment detected. Exiting..."
}
Stop-Transcript