Write-Host  -ForegroundColor Cyan "Starting Brooks' Custom OSDCloud ..."
Start-Sleep -Seconds 5

#Change Display Resolution for Virtual Machine
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}
Write-Host  -ForegroundColor Cyan "Importing the OSDCloud PowerShell Module"
Install-Module OSD -Force
Import-Module OSD -Force

if ($os.name -eq "|x:\windows|")
	{
		
	write-host BIOS Version: UEFI -ForegroundColor yellow
		
	}
	
	Write-Host "================== Main Menu =========================="
	Write-Host "===============www.brookspeppin.com ================="
	Write-Host "===================@brookspeppin ===================="
	Write-Host "========By Brooks Peppin (bpeppin@vmware.com)=========="
	Write-Host "======================================================="`n
	Write-Host "1: Zero-Touch Win10 Latest | English | Enterprise"
	Write-Host "2: Zero-Touch Win10 n-1 | English | Enterprise"
	Write-Host "3: I'll select it myself"
	Write-Host "4: Exit`n"
	$input = Read-Host "Please make a selection"
	switch ($input)
	{
		'1' { Start-OSDCloud -OSLanguage en-us -OSBuild 21H1 -OSEdition Enterprise -ZTI } #Call Image_from_network function
		'2' { Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Enterprise -ZTI } #Call Image_from_Network function
		'3' { Start-OSDCloud	} #Call Image_from_Network function
		'4' { Exit		}
	}


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