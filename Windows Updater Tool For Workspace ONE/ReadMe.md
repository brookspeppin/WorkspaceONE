# Windows Updater Tool for Workspace ONE

## Overview
- **Author**: Brooks Peppin
- **Website**: www.brookspeppin.com
- **Date Updated**: Apr 27, 2021

## SYNOPSIS
This tool supplements Workspace ONE's Windows Update for Business profiles and approval features.  It downloads the cab file for the specific Windows Update, zips it up with a few scripts, and then uploads to Workspace ONE for deployment via the Software Distribution engine.  The main use cases this tool solves for are:
1. Times you need to rapidly push down an update and force a restart
2. When you are beyond the 365 day deferral of the feature upgrade and Windows will no longer take regular patches until you upgrade the feature version. This can buy you a bit more time. 
![Screenshot1](https://user-images.githubusercontent.com/33036379/116281916-6db49580-a747-11eb-92be-35cfebb81bca.png)

##Requirements##
- Run on a Windows 10 "host" client. Do not deploy this tool to your endpoints. 
- Windows 10 versions 1809 or higher. If you are running 1803 or earlier, please upgrade!
- This tool does the majority of updates available in Windows Update but it does NOT do feature upgrades. 
- REST API Key
- Credentials for an adminstrator (you can use your own credentials or create a service account with appropriate admin permissions). 

## DESCRIPTION
1. Double-click WindowsUpdaterTool.exe to load the tool.  If Windows Defender Smart screen blocks it from running, click "More Info, then Run Anyway". Or you can run the WindowsUpdaterTool.Export.ps1 file instead.
2. Select the version of Windows 10 you would need
3. The latest patches for that version will be populated in the table below. Select the patch you need.
4. Fill out the Workspace ONE info section
	- Server: Need to be in https://asXXXX.awmdm.com. Example: https://as1380.awmdm.com
	- API Key: Find this under All Settings > System > Advanced > REST API. You can use the built-in one or create your own.
	- Group ID: Find this by mousing over the Organization Group dropdown at the top of the WS1 UEM Console
	- Username/Password: enter credentials of an admin account. This will be encoded as BASE64 and then sent over https 
5. Configure App Settings
	- Dependency App: Check this if you want to sequence apps together, such as a Servicing Stack so that you can deploy them in sequence. Don't forget to link them together in the UEM console.
	- Force Restart: Will force a 5 min restart window after the update is installed.
	- Do Not Restart: Does not force a reboot at all
	- User Deferred Restart (recommend). This will prompt the user with a toast notification that a restart is required. They can "restart now" or defer. You can set the amount of days anywhere between 0-7 before the system will force the reboot. Don't set it to 0 as this acts the same as the "Force Reboot" option and is not a great user experience. 
		


