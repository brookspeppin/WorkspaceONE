<#
# This script will search for a value and return the corresponding value in the second field.
# It will then popup a Windows setup compatibility scan results window in plain text using PowerShell based on the _SMSTSOSUpgradeActionReturnCode variable
# niall brady 2016/5/14
# Updated: Bpeppin 2017/11/18
#
# The following variable _SMSTSOSUpgradeActionReturnCode from https://technet.microsoft.com/en-us/library/mt629380.aspx will be used to determine the return code.
# Here are the KnownErrorCodes to popup messages against via https://technet.microsoft.com/en-us/library/mt629396.aspx#BKMK_UpgradeOS
#
# MOSETUP_E_COMPAT_SCANONLY (OxC1900210) No compatibility issues ("success").
# MOSETUP_E_COMPAT_INSTALLREQ_BLOCK (0xC1900208) Actionable compatibility issues.
# MOSETUP_E_COMPAT_MIGCHOICE_BLOCK (0xC1900204) Selected migration choice is not available. For example, an upgrade from Enterprise to Professional.
# MOSETUP_E_COMPAT_SYSREQ_BLOCK (OxC1900200) Not eligible for Windows 10.
# MOSETUP_E_COMPAT_INSTALLDISKSPACE_BLOCK (0xC190020E) Not enough free disk space.
#>

Function LogWrite
{
	Param ([string]$logstring)
	Add-content $Logfile -value $logstring
	write-host $logstriing
}

$Logfile = "C:\VMware_IT\Logs\WindowsSetupCompatScan.log"
$Manufacturer = ((Get-WmiObject -Class win32_computersystem).Manufacturer)
$Model = ((Get-WmiObject -Class win32_computersystem).Model)
$Date = Get-Date
LogWrite "Starting Windows Setup compatibility scan results script"
LogWrite "The following hardware was detected: $Manufacturer $Model"

#Hide the progress dialog
$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

# unrem the next line to test manually thanks Nickolaj for the [int64] tip
#[int64]$decimalreturncode="3247440400"
#
# rem the next two lines to test manually
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
write-host "The task sequence step returned the following return code: $tsenv.Value("_SMSTSOSUpgradeActionReturnCode")"
[int64]$decimalreturncode = $tsenv.Value("_SMSTSOSUpgradeActionReturnCode")
#
# convert the decimal value to HEX
$hexreturncode = "{0:X0}" -f [int64]$decimalreturncode
LogWrite "The original decimal returncode was: $decimalreturncode"
LogWrite "The converted HEX returncode is: $hexreturncode"

$row = 0
$hexreturncode = $hexreturncode.ToUpper()
$KnownErrorCodes = @(("C1900210", "C1900208", "C1900204", "C1900200", "C190020E", "C1900107"), ("No compatibility issues.", "Incompatible apps or drivers.", "Selected migration choice is not available. For example, incompatible language.", "Not eligible for Windows 10.", "Not enough free disk space. 20GB free space required.", "Unsupported Operating System."))

foreach ($value in $KnownErrorCodes)
{
	$col = 0
	#LogWrite "" -ForegroundColor white
	#LogWrite "$hexreturncode" -nonewline -ForegroundColor green
	#LogWrite ""
	foreach ($element in $value)
	{
		#write-host "Searching row[$row]col[$col]" -nonewline -ForegroundColor white
		#write-host "Row #" $row "Col #" $col "Value =" $value[$col]
		#write-host "$hexreturncode".ToUpper()
		
		If ($value[$col].Contains($hexreturncode))
		{
			LogWrite "Found value at $row $col" -ForegroundColor red
			# add +1 to skip down to the corresponding row...
			$row++
			$result = $KnownErrorCodes[$row][$col]
			break
			#exit
		}
		else
		{ $result = "Unknown Value: " }
		$col++
	}
	$row++
	# quit after searching the first row, if you want to search more rows remove the If group
	If ($row -ge 1)
	{
		LogWrite ""
		LogWrite "The corresponding value to return is: " -nonewline
		LogWrite -foregroundcolor Green $result
		LogWrite "Windows 10 compatibility scan ran on: $date ending script."
		break
	}
	else
	{ }
}
if ($hexreturncode -ne "C1900210" -and $hexreturncode -ne "0")
{
	$EmailFrom = "email address here"
	$EmailTo = "email address here"
	#$BCC = "email address here"
	$SmtpServer = "smtp server here"
	$date = Get-Date
	$Log1 = "C:\VMware_IT\Logs\WindowsSetupCompatScan.Log"
	
	$message = @{
		Subject	    = "Failure Detected - In-Place Upgrade $env:computername"
		Body	    = "<br>Logs attached. Full logs located at \\logpathhere\$env:computername<br>"
		From	    = "$EmailFrom"
		To		    = "$EmailTo"
		SmtpServer  = "$SmtpServer"
		Attachments = "$Log1"
	}
	
	Write-Verbose "Sending e-mail of logs"
	
	Send-MailMessage @message -BodyAsHtml
	$tsenv.Value("WindowsSetupCompatibilityScan") = "FAILED"
}
else
{
	$EmailFrom = "email address here"
	$EmailTo = "email address here"
	#$BCC = "email address here"
	$SmtpServer = "smtp server here"
	$date = Get-Date
	$Log1 = "C:\VMware_IT\Logs\WindowsSetupCompatScan.Log"
	
	$message = @{
		Subject	    = "Failure Detected - In-Place Upgrade $env:computername"
		Body	    = "<br>Logs attached. Full logs located at \\logpathhere\$env:computername<br>"
		From	    = "$EmailFrom"
		To		    = "$EmailTo"
		SmtpServer  = "$SmtpServer"
		Attachments = "$Log1"
	}
	
	Write-Verbose "Sending e-mail of logs"
	
	Send-MailMessage @message -BodyAsHtml
	
	$RegPath = "HKLM:\Software\VMware_IT"
	New-Item -Path $RegPath -Value "default value" -ErrorAction SilentlyContinue
	New-ItemProperty -path $RegPath -Name Win10UpgradeReady -PropertyType String -Value "Yes" -Force
	$tsenv.Value("WindowsSetupCompatibilityScan") = "OK"
}




