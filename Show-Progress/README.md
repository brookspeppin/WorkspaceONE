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


## Parameters
**Interval**

Interval in seconds between each toast. 90 seems like a pretty good balance of notifying enough, but not frequently. 