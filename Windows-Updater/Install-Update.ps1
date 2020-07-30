<#	
.NOTES
	===========================================================================
	 Created by:	bpeppin@vmware.com | www.brookspeppin.com 
	 Organization:	VMware, Inc.
     Filename:     	Install-update.ps1
     Date:          July 28, 2020
	===========================================================================
	.DESCRIPTION
		Installs a windows update that is in .msu format. 
        
#>
$KB = "kb4558998" #2020-07 Cumulative Update for Windows 10 Version 1809 for x64-based Systems (KB4558998)
$Filename = (Get-ChildItem -Filter "*.msu").name
$fullpath = "$PSScriptRoot\$Filename"
#$URL = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2020/03/windows10.0-kb4541335-x64_aa70c2bee5f7d6e375a68d1f325427ecce36ac23.cab"

If (!(Test-Path C:\Temp)) {
    mkdir c:\temp
}
Start-Transcript "C:\Temp\Install-Update-$Filename.log"
function CheckKB {
    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [String]$KB
    )
    Write-Host "Checking if $KB is installed..."
    If ((get-hotfix).HotfixID -contains $KB) {
        #successfully installed
        Return $true
    }
    else {
        #failed to install
        Return $false
    }
    
}

#Pre-Checking installation of KB
if (CheckKB -KB $KB) {
    Write-Host "KB $KB already installed. Exiting."
    Exit 0
}
else {
    #Write-Host "Starting BitsTransfer download of $KB"
    #Start-BitsTransfer -Source $URL -Destination $fullpath | Out-Host
    Try {
        Write-Host "Installing $KB with from $fullpath"
        start-process wusa -ArgumentList "$fullpath /quiet /norestart /log:c:\temp\wusa.evt" -Wait
        #DISM.exe /online /add-package /PackagePath:$fullpath /NoRestart | Out-Host
    }
    catch {
        $message = "TRAPPED: {0}: '{1}'" -f ($_.Exception.GetType().FullName), ($_.Exception.Message)
        Write-host $message
        Exit 1
    }
}

if (CheckKB -KB $KB) {
    Write-Host "$KB successfully installed. Cleaning up file to free up space. Exiting with reboot code 3010."
    Remove-Item $fullpath -Force
    Exit 3010
}
else {
    Write-Host "$KB not installed. Exiting with error code 1."
    Exit 1
}

Stop-Transcript
