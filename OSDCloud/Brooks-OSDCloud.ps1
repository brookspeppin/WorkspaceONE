Write-Host  -ForegroundColor Yello "Starting Brooks' Custom OSDCloud ..."

Write-Host "================== Main Menu ==========================" -ForegroundColor Yellow
Write-Host "===============www.brookspeppin.com =================" -ForegroundColor Yellow
Write-Host "===================@brookspeppin ===================="-ForegroundColor Yellow
Write-Host "========By Brooks Peppin (bpeppin@vmware.com)=========="-ForegroundColor Yellow
Write-Host "======================================================="`n-ForegroundColor Yellow
Write-Host "1: Zero-Touch Win10 21H1 | English | Enterprise"-ForegroundColor Yellow
Write-Host "2: Zero-Touch Win10 20H2 | English | Enterprise"-ForegroundColor Yellow
Write-Host "3: I'll select it myself"-ForegroundColor Yellow
Write-Host "4: Exit`n"-ForegroundColor Yellow
$input = Read-Host "Please make a selection"-ForegroundColor Yellow
Write-Host  -ForegroundColor Yellow "Starting OSDCloud PowerShell Module"

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