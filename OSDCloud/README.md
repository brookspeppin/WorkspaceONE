# OSDCloud_Starter.ps1

## Overview
- **Author**: Brooks Peppin
- **Website**: www.brookspeppin.com
- **Date Updated**: May 12, 2021

## SYNOPSIS
Enables quick setup of the OSDCloud module by David Segura https://osdcloud.osdeploy.com/get-started. For complete functions and modules, please visit his site. And give him the credit for building OSDCloud!

## PARAMETERS
**Parameter –ADK**
Specifies that you want the script to automatically install the Windows 10 ADK and WinPE ADK onto your system. This reall only needs to be run once or if there is a new version.

**Parameter –Workspace**
Specifies the folder (workspace) where OSDCloud will store it's content.

**Parameter –WinPEDrivers**
Specifies which driver vendor(s) to add in WinPE. Separate by commas. Valid options are Dell,HP,Nutanix,VMware,Wifi.

**Parameter –New**
Specifies that you would like to cleanly install the latest OSDCloud powershell module and create a new template.

**Parameter –CustomURL**
Specifies a custom URL that you want to have OSDCloud launch on first boot inside of WinPE. Recommend this be a PS script hosted on github and copy/paste the "Raw" URL.

**Parameter –BuildISO**
Parameter to build a new ISO

**Parameter –BuildUSB**
Parameter to build a USB key

## EXAMPLE
Installs ADK, sets the workspace to C:\OSDCloud, installs Dell drivers in WinPE and installs OSDCloud fresh
.\OSDCloud_Starter.ps1 -ADK -Workspace C:\OSDCloud -WinPEDrivers Dell -New

Modifies an existing OSDCloud template to add in the custom URL
.\OSDCloud_Starter.ps1 -CustomURL https://raw.githubusercontent.com/brookspeppin/WorkspaceONE/master/OSDCloud/Brooks-OSDCloud.ps1 -BuildISO

Builds a USB key
.\OSDCloud_Starter.ps1 -BuildUSB



