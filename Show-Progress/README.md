# Show-Progress.ps1

## Overview
- **Author**: Brooks Peppin
- **Website**: www.brookspeppin.com
- **Date Created**: 05/20/2018

## SYNOPSIS
This Powershell script shows a popup toast notification on Windows 10 and watches for reg keys created by the AirWatch Software Distribution (SFD) engine. This is primarily used to deploy during device provisioning as part of the OOBE process so that you can see the progress of apps getting installed. The reg keys it is watching are located here:	HKEY_LOCAL_MACHINE\SOFTWARE\AirWatchMDM\AppDeploymentAgent\Queue

**Requirements**
- Recommend you deploy via Airwatch Product Provisioning so that it can run independently of Software Distribution framework.

## DESCRIPTION
When run, if command line parameters are not provided, this script will prompt you to select a csv file that contains Device Serial number mapping to desired End User.

## EXAMPLE

    .\Show-Progress.ps1 -Interval 90

##Modifications Required
- Update Show-Progress.vbs to reflect where on client Show-Progress.ps1 is located
- Updated $icon variable in Show-progess.ps1 to reflect where on client you put ws1.jpg
	
## Parameters
**Interval**

Interval in seconds between each toast. 90 seems like a pretty good balance of notifying enough, but not frequently. 

## Deployment in WorkspaceONE
1. Download Show-Progress.ps1, Show-Progress.vbs, and ws1.jpg files
2. Decide where on client you want these to download to and edit Show-Progress.vbs since it is hard coded (i.e. C:\VMware_IT\Installs\Show-progess.ps1)
2. In AW Console, go to Devices, Staging and Provisioning, Components, Files/Action
3. Add a new file/action
4. Add all 3 files in "Files" tab. Include full path you decided in step 2.
5.  In Manifest, add an Action: [Run, Admin, C:\VMware_IT\Installs\Show-Progress.vbs, 0]
6. Save, then go up to Product list and create a new product with this manifest. 
7. Deploy to smart group