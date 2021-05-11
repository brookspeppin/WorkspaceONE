Write-Host  -ForegroundColor Cyan "Starting Brooks' Custom OSDCloud ..."

Write-Host "================== Main Menu =========================="
Write-Host "===============www.brookspeppin.com ================="
Write-Host "===================@brookspeppin ===================="
Write-Host "========By Brooks Peppin (bpeppin@vmware.com)=========="
Write-Host "======================================================="`n
Write-Host "1: Zero-Touch Win10 21H1 | English | Enterprise"
Write-Host "2: Zero-Touch Win10 20H2 | English | Enterprise"
Write-Host "3: I'll select it myself"
Write-Host "4: Exit`n"
$input = Read-Host "Please make a selection"
Write-Host  -ForegroundColor Cyan "Starting OSDCloud PowerShell Module"

Import-Module OSD -Force
Install-Module OSD -Force
	switch ($input)
	{
		'1' { Start-OSDCloud -OSLanguage en-us -OSBuild 21H1 -OSEdition Enterprise -ZTI } 
		'2' { Start-OSDCloud -OSLanguage en-us -OSBuild 20H2 -OSEdition Enterprise -ZTI } 
		'3' { Start-OSDCloud	} 
		'4' { Exit		}
	}



#Restart from WinPE

wpeutil reboot