<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
	 Created on:   	2/8/2017 2:34 PM
	 Created by:   	bpeppin
     Updated: Bpeppin, 2/8/17
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Airwatch Enrollment during imaging using Airwatch APIs to create device pre-registration. Copies a login script that will complete enrollment on user login. 
#>

#Variable Section
$version = 'v1'
$serial = (gwmi win32_bios).serialnumber
$URL = "https://cnxxx.awmdm.com/api" #Airwatch API server
$APIkey = "xxxx" #AW API Key from AW console 
$cred = "xxxxx" #AW admin base64 encoded in format username:password (can use to encode/decode http://coderstoolbox.net/string) 
$ownership = "C" #denotes the device will be register as company owned. Use "E" for company owned.
$OG = "xxx" #organization group information where the devices will be registered to
$localscriptpath = "C:\VmwareIT\Installs\"
function Get-LogDir #Uses MDT/SCCM default log location
{
	try
	{
		$ts = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
		if ($ts.Value("LogPath") -ne "")
		{
			$logpath = $ts.Value("LogPath")
		}
		else
		{
			$logpath = $ts.Value("_SMSTSLogPath")
		}
	}
	catch
	{
		$logpath = $env:TEMP
	}
	
	return $logpath
}
$logpath = Get-LogDir
$logFile = "$logPath\AWEnroll-$version.log"
Start-Transcript $logFile
Write-Host "Script version is: $version"

#Getting user info from MDT
$ts = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
$primaryuser = $ts.Value("Administrators001")
Write-Host "Primary user before split=" $primaryuser
if ($primaryuser -eq "")
{
	Write-host "User info is blank, exiting."
	exit 0 #if no user input is giving in MDT wizard, this will exit
	
}

#Removing domain\ from username
$primaryuser = ($primaryuser.Replace("`"","")).split('\')[-1]
Write-Host "Primary user= $primaryuser"

#main REST HEADER
$header = @{
	"Authorization"  = "Basic $cred";
	"aw-tenant-code" = $APIkey;
	"Accept"		 = "application/json";
	"Content-Type"   = "application/json";
}


#Checking for existing Registration Token
Write-host "Checking for existing Registration Token"
$apipath = "/system/users/enrollmenttoken/search?serialnumber="
$registration = Invoke-RestMethod -Uri "$URL$apipath$serial" -Headers $header
#create new registration if no registration exists
#Gets userID number as the API requires it
$apipath = "/system/users/search?username=$primaryuser"
$userid = (Invoke-RestMethod -Uri "$URL$apipath" -Headers $header).Users
$userid = ($userid | where { ($_.username -like "$primaryuser") -and ($_.group -notlike "staging") }).ID.Value #ensures its a real acccount
$body = @{
	'LocationGroupID' = "$OG" #enroll into Production OG
	'FriendlyName'    = "$primaryuser";
	'Ownership'	      = "$ownership"; #company owned
	'SerialNumber'    = "$serial";
	'PlatformID'	  = '12'; #Windows Desktop platform ID
	
}
$json = $body | ConvertTo-Json
If ($registration -eq "")
{
	Try
	{
		Write-host "No device registration found. Creating new."
		For ($i = 0; $i -lt $userid.Length; $i++) #This loop is really just in case it finds more than one user based on username lookup in the console, it will register it to both
		{
			$user = $userid[$i]
			$apipath = "/system/users/$user/registerdevice"
			write-host $apipath
			Invoke-RestMethod -Uri "$URL$apipath" -Method POST -Headers $header -Body $json
		}
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
	Write-host "Device registration already exists. Checking now for matching registration..."
	If ($registration.device.username -eq $primaryuser)
	{
		$registration = $registration.device.username
		Write-Host "Device $serial is registered to $registration and imaging user is $primaryuser. Moving on."
	}
	else
	{
		Write-Host "Device $serial is registered to $registration and imaging user is $primaryuser."
		Write-Host "Registration does not match. Updating record."
		$apipath = "/system/users/$userid/registerdevice"
		Invoke-RestMethod -Uri "$URL$apipath" -Method POST -Headers $header -Body $json
		
	}
}


#Copying install batch file and AW agent to startup folder
xcopy .\AirwatchAgent.msi $localscriptpath /y
xcopy .\AWEnrollLogin.ps1 $localscriptpath /y
xcopy .\AWEnrollLogin.vbs "C:\Users\default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\" /y
Stop-Transcript
