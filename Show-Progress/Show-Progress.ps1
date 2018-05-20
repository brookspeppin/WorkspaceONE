<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
	 Created on:   	5/20/2018 1:24 PM
	 Created by:   	bpeppin, @brookspeppin, brookspeppin.com
	 Organization: 	VMware, Inc.
	 Filename:     	Show-Progress.ps1
	===========================================================================
	.DESCRIPTION
		Shows a popup Toast notification on Windows 10 and watches for reg keys created by
		AirWatch Software Distribution (SFD). Reg keys are located here:
		HKEY_LOCAL_MACHINE\SOFTWARE\AirWatchMDM\AppDeploymentAgent\Queue

	.EXAMPLE
	From CMD:
	Powershell -executionpolicy bypass -command "& .\Show-Progress.ps1 -Interval 90"

	.EXAMPLE
	From powershell
	powershell -executionpolicy bypass -file Show-Progress.ps1 -Interval 90

	.EXAMPLE
	Or using Show-Progress.vbs (just update the hard coded path in vbs file)

	.USAGE
	Recommend to deploy via Airwatch Product Provisioning so that it can run independently of
	Software Distribution framework.

	.CREDIT
	Parts of this script taken from the following people:
	Credit: Josh King (https://gist.github.com/Windos/9aa6a684ac583e0d38a8fa68196bc2dc) and
	Shawn Esterman -Twitter @ShawnDotTweet, https://gist.github.com/ShawnEsterman/8b9637fa7042ffa209be46f751a192fa

	
#>
[CmdletBinding()]
param
(
	[parameter(Mandatory = $true)]
	[Int]
	$Interval # number of seconds in between each toast
)

#Variable Section
$version = 'v4'
$locallogpath = "C:\VMware_IT\Logs" #local path for logs
$localfilename = "Show-Progress-$version.log" #local log file name
$outpath = "C:\VMware_IT\Installs"
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$icon = "c:/VMware_IT/Installs/ws1.jpg" #need to use forward slashes
$pretimeout = "10" #number of min script will wait for the queue to fill up before quitting
$duration = "60" #number of min toast notification loop will run for before quitting. 
#Ensuring log locations exist
$partofdomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain

If ((Test-Path $locallogpath) -eq $false)
{
	md $locallogpath
}

Start-Transcript $locallogpath\$localfilename
if ($partofdomain -eq $true) #I've added this section so that it only runs on my azure AD joined systems (optional)
{
	Write-Host "Part of domain: $partofdomain. Exiting script."
	
	Exit 0
}
Write-Host "Script version is: $version"
Write-Host "Script path is $PSScriptRoot"
$Arch = (Get-Process -Id $PID).StartInfo.EnvironmentVariables["PROCESSOR_ARCHITECTURE"]
if ($Arch -eq 'x86')
{
	Write-Host 'Running 32-bit PowerShell'
}
elseif ($Arch -eq 'amd64')
{
	Write-Host 'Running 64-bit PowerShell'
}
Write-Host "Script started at" (Get-Date).AddSeconds($TotalTime)
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]

function Show-ToastNofication
{
<#
.Synopsis
   Displays a Toast notification in Windows 10 with PowerShell
.DESCRIPTION
   Displays a Toast notification in Windows 10 with PowerShell
.EXAMPLE
   Show-ToastNofication -Title 'Configuration of Windows 10 Complete!' -Body "Enjoy your new PC"

#>
	
	[CmdletBinding()]
	Param (
		[System.String]$Title,
		[System.String]$Body
	)
	
	$APP_ID = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
	
	$template = @"
<toast>
    <visual>
        <binding template="ToastImageAndText02">
            <text id="1">$($Title)</text>
            <text id="2">$body</text>
			<image id='1' src="file:///$icon" />
        </binding>
    </visual>
</toast>
"@
	
	$ToastXml = New-Object Windows.Data.Xml.Dom.XmlDocument
	$ToastXml.LoadXml($Template)
	
	$ToastNotifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($APP_ID)
	$ToastNotifier.Show($ToastXml)
}

#Sets a 10 min timeout so that it doesn't run forever waiting for the queue
$timeout = new-timespan -Minutes $pretimeout
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout)
{
	
	$Queue = "HKLM:\SOFTWARE\AirWatchMDM\AppDeploymentAgent\Queue\*"
	if (Get-Item $Queue -ErrorAction Ignore)
	{
		break
	}
	else
	{
		Write-Host "Waiting for AWSFD Queue to fill up..."
		Start-Sleep 30
		$Queue = "HKLM:\SOFTWARE\AirWatchMDM\AppDeploymentAgent\Queue\*"
	}
	
}
#Exits if timeout has exceeded
If ($sw.elapsed -gt $timeout)
{
	Write-Host "Timeout exceeded ($timeout min). Quitting."
	Exit 0
}

Start-Sleep 10
$timeout = new-timespan -Minutes $duration
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout)
{
	
	$Queue = "HKLM:\SOFTWARE\AirWatchMDM\AppDeploymentAgent\Queue\*"
	while (Get-Item $Queue -ErrorAction ignore)
	{
		$count = (Get-Item $Queue).count
		Write-Host "Installing apps in the background. `n$count more to go	..."
		Write-Host "Time elapsed =" $sw.elapsed.minutes "min"
		Show-ToastNofication -Title 'Configuring Windows 10' -Body "Installing apps in the background. `n$count more to go."
		Start-Sleep $interval
		$Queue = "HKLM:\SOFTWARE\AirWatchMDM\AppDeploymentAgent\Queue\*"
	}
		
}
#Exits if timeout has exceeded
If ($sw.elapsed -gt $timeout)
{
	Write-Host "Timeout exceeded ($timeout min). Quitting."
	Exit 0
}


Show-ToastNofication -Title 'Configuration of Windows 10 Complete!' -Body "Enjoy your new PC"



Stop-Transcript