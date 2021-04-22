Write-Host  -ForegroundColor Cyan "Starting Brooks' Custom OSDCloud ..."
Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

#Make sure I have the latest OSD Content
#Write-Host  -ForegroundColor Cyan "Updating the awesome OSD PowerShell Module"


Write-Host  -ForegroundColor Cyan "Importing the sweet OSD PowerShell Module"
Install-Module OSD -Force
Import-Module OSD -Force

#TODO: Spend the time to write a function to do this and put it here
#Write-Host  -ForegroundColor Cyan "Ejecting ISO"
#Write-Warning "That didn't work because I haven't coded it yet!"
#Start-Sleep -Seconds 5

#Start OSDCloud ZTI the RIGHT way
Write-Host  -ForegroundColor Cyan "Start OSDCloud with Parameters: 20H2, ENT, Zero-Touch"
Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Enterprise -ZTI
#Start-OSDCloud -OSLanguage en-us

#Anything I want  can go right here and I can change it at any time since it is in the Cloud!!!!!
Write-Host  -ForegroundColor Cyan "Starting OSDCloud PostAction ..."
#x:\OSDCloud\Autopilot\Profiles\DownloadFilesFromRepo.ps1
#$USB_Boot = ((Get-Volume).where({ $_.FileSystemLabel -eq "OSDCloud" })).DriveLetter + ":"
$usb = ((Get-Volume).where({ ($_.FileSystemLabel -eq "OSDCloud") -and ($_.DriveType -eq "Fixed") })).DriveLetter + ":"
#$usb_source = ((Get-Volume).where({ $_.FileSystemLabel -eq "USB-Source" })).DriveLetter + ":"
$path = "C:\programdata\vmware\"
if(!(Test-Path $path)){
    mkdir $path
}
$filename = "AwProvAgent-x64.msi"
Copy-Item -Path $usb\ws1\$filename -Destination $path 

Copy-Item -Path $usb\ws1\VMwareWS1ProvisioningTool.exe -Destination $path
Copy-Item -Path $usb\ws1\VMwareWS1ProvisioningTool.exe.config -Destination $path
Copy-Item -Path $usb\ws1\unattend_OSDCloud.xml -Destination C:\Windows\Panther\Invoke-OSDSpecialize.xml -Force


#Restart from WinPE
#Write-Host  -ForegroundColor Cyan "Restarting in 5 seconds!"
#pause
wpeutil reboot