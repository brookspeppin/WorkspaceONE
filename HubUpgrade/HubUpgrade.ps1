# --------------------------------------------------------------------------------------------------------------------
# Author:Brooks Peppin, VMware, Inc.
# Date Updated: 08/17/21
# Description: Windows 10 Hub Upgrade Via Software Distribution
# Tested on Hub Version 21.10 > 21.02
# --------------------------------------------------------------------------------------------------------------------


$currentLocation = Split-Path -Path $MyInvocation.MyCommand.Definition
$msiPath = $currentLocation + "\AirwatchAgent.msi"
$LogFilePath = "$env:ProgramData\Airwatch\UnifiedAgent\Logs"
$LogFileName = "HubUpgrade.log"

function Write-Log {

    Param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
	
    If ((Test-Path $LogFilePath) -eq $false) {
        mkdir $LogFilePath
    }
	
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $time + '...' + $Message | Out-File -FilePath $logfilename -Append
    Write-Host $Message
}

#Start Main Function
$installBaseDirectory = "INSTALLDIR"
$agentRegistryLocation = (Get-ItemProperty -Path HKLM:\SOFTWARE\AIRWATCH -Name $installBaseDirectory).$installBaseDirectory
$installAgentUILocation = $agentRegistryLocation + "\AgentUI"
$updateFolder = $installAgentUILocation + "\Update"
$hub = (Get-ItemProperty HKLM:\Software\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\* | where-Object { $_.DisplayName -like "Airwatch*" -or $_.DisplayName -like "Workspace ONE Intelligent Hub*" })
$version = $hub.DisplayVersion
$guid = $hub.PSChildname

Write-Log "Current Workspace ONE Version: $version"
Write-Log "Current Workspace ONE App GUID: $GUID"
Write-Log "Checking if '$updateFolder' folder exists..."
if (Test-Path $updateFolder) {
    Write-Log "True, folder exists."
}
else {
    Write-Log "False, folder does not exist. Creating..."
    mkdir $updateFolder
}

Try {
    Write-Log "Copying File."
    $copiedFile = Copy-Item -path $msiPath -Destination $updateFolder -PassThru
}
catch {
    $exception = $_
    Write-Log "Error copying AirwatchAgent.msi: $exception"
}

Write-log "Checking for $installAgentUILocation\AW.WinPC.Updater.exe"
if(Test-Path $installAgentUILocation\AW.WinPC.Updater.exe){
    Write-Log "Running AW.WinPC.Updater.exe from $installAgentUILocation"
    Start-Process -FilePath "AW.WinPC.Updater.exe" -WorkingDirectory $installAgentUILocation -Wait
}else {
    Copy-Item -path "$installAgentUILocation\Resources\AW.WinPC.Updater.exe" -Destination $installAgentUILocation -PassThru
    Start-Process -FilePath "AW.WinPC.Updater.exe" -WorkingDirectory $installAgentUILocation -Wait

}
$hub = (Get-ItemProperty HKLM:\Software\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\* | where-Object { $_.DisplayName -like "Airwatch*" -or $_.DisplayName -like "Workspace ONE Intelligent Hub*" })
$version = $hub.DisplayVersion
$guid = $hub.PSChildname
Write-Log "After Upgrade Workspace ONE Version: $version"
Write-Log "After Upgrade Workspace ONE App GUID: $GUID"
