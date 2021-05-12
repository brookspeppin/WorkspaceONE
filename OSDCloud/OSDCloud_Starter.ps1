#OSDCloud creator tool
# OSDCloud module created by David Segura
# https://osdcloud.osdeploy.com/get-started
# 
# This mini script written by Brooks Peppin
#--------------------------------------------
#----------------Pre-Reqs--------------------
#--------------------------------------------
[CmdletBinding()]
param (
    [switch]$ADK,
    [string]$workspace,
    [ValidateSet('Dell', 'HP','Nutanix','VMware','Wifi')]
    $WinPEDrivers,
    [switch]$New,
    [switch]$BuildISO,
    $CustomURL,
    [switch]$BuildUSB
)



#Install Win10 ADK and WinPE ADK
If($ADK){
    Write-Host "Downloading ADKsetup.exe..."
    $downloads = "$env:USERPROFILE\downloads"
    Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2120254" -OutFile $downloads\adksetup.exe
    
    Write-Host "Installing ADK for Windows 10"
    start-process -FilePath "$downloads\adksetup.exe" -ArgumentList "/quiet /features OptionId.DeploymentTools" -Wait
    
    Write-Host "Downloading ADKWinpesetup.exe..."
    Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=2120253" -OutFile $downloads\adkwinpesetup.exe
    Write-Host "Installing ADK WinPE for Windows 10"
    start-process -FilePath "$downloads\adkwinpesetup.exe" -ArgumentList "/quiet /features OptionId.WindowsPreinstallationEnvironment" -Wait
}

if($New){
    Write-Host "Installing OSDCloud Powershell Module"
    Install-Module OSD -Force
    
    Write-Host "Setting up OSDCloud template..."
    New-OSDCloud.template -Verbose

}
if($workspace){

    New-OSDCloud.workspace -WorkspacePath $workspace
}

if ($WinPEDrivers) {
    Edit-OSDCloud.winpe -CloudDriver $WinPEDrivers
}

if($CustomURL){
    Edit-OSDCloud.winpe -WebPSScript $CustomURL 
}
if($BuildISO){
    New-OSDCloud.iso
}

if($BuildUSB){
    New-OSDCloud.usb
}