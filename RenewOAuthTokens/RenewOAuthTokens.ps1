<#	
	.NOTES
	===========================================================================
	 Created on:   	9/7/2021
	 Created by:   	Brooks Peppin, www.brookspeppin.com
	 ==========================================================================
	.DESCRIPTION
		Sample script for renewing OAuth tokens in WS1 UEM. From Blog https://www.brookspeppin.com/2021/09/07/how-to-renew-oauth-tokens-in-workspace-one-uem/
#>


#variables
$server = "https://cn1506.awmdm.com"

Function Get-WorkspaceOneOAuth {
    #============================================================================================
# Create client ID and secret from WS1 UEM admin console 
# UEM > Groups & Settings > Configurations > OAuth Client Management
# Example: https://cnXXXX.awmdm.com/AirWatch/aa/#/configurations/oauth-clients

    Write-Log "Getting OAuth Token for $env"
    switch ($env) {
        'UAT' { 

            $client_id = ""
            $client_secret = ""
            $access_token_url = "https://uat.uemauth.vmwservices.com/connect/token"
            $body = @{
                grant_type    = "client_credentials"
                client_id     = $client_id
                client_secret = $client_secret
            }
        }
        'Prod' { 


            $client_id = ""
            $client_secret = ""
            $access_token_url = "https://na.uemauth.vmwservices.com/connect/token"
            $body = @{
                grant_type    = "client_credentials"
                client_id     = $client_id
                client_secret = $client_secret
            }
            # $access_token = (Invoke-WebRequest -Method Post -Uri $na_access_token_url -Body $body -UseBasicParsing | ConvertFrom-Json).access_token

        }
        Default {}
    }
    #Make an API call to get oauth token. FYI: token is valid for 1 hour
    try {

        $response = Invoke-WebRequest -Method Post -Uri $access_token_url -Body $body -UseBasicParsing
        $response = $response | ConvertFrom-Json
        $oauth_token = [string]$($response.access_token)

    }
    catch {
        $ErrorMessage = $PSItem | ConvertFrom-Json
        Write-Log "Failed to create OAuth Token for: $env with following ErrorCode: $($ErrorMessage.errorCode) - $($ErrorMessage.message)" -ForegroundColor Red
    }

    Return $oauth_token

}

function Get-Header
{
  [CmdletBinding()]
  Param(
      [Parameter(Mandatory = $True)]
      [string]$version
  )   
  $oauthToken = Get-WorkspaceOneOAuth
  $header = @{
      "Authorization" = "Bearer " + $oauthToken;
      "Accept" = "application/json;version=$version";
      "Content-Type" = "application/json"
  }
  switch ($version) {
      '1' { 
            $global:OAuthTimer1 = [System.Diagnostics.Stopwatch]::StartNew()
            #$(@($Wave_users.username.count))
           # Write-Log "Oauth timer started: $(@($Global:OAuthtimer1.Elapsed.TotalMinutes)) "
         }
      '2' {  
           $global:OAuthTimer2 = [System.Diagnostics.Stopwatch]::StartNew()
          # Write-Log "Oauth timer started:$global:OAuthTimer2 "
          # Write-Log "Oauth timer started: $(@($global:OAuthTimer2)) "
         }
      Default {}
  }

    Write-Log "Oauth Token: $oauthToken "
    return $header
}

if(($Global:OAuthtimer1.Elapsed.TotalMinutes -gt 55) -or ($null -eq $Global:OAuthtimer1)){
    Write-Log "OAuth token expiring within 5 min or doesn't exist, renewing..."
    $global:header_v1 = Get-Header -version 1
}


if(($Global:OAuthtimer2.Elapsed.TotalMinutes -gt 55) -or ($null -eq $Global:OAuthtimer2)){
    Write-Log "OAuth token expiring within 5 min or doesn't exist, renewing..."
    $global:header_v2 = Get-Header -version 2
}

Function Get-ProfileStatus {
    param (
        $DeviceID
    )
    #Write-Log "Checking profiles on device: $deviceID"
    $Uri = "$server/API/mdm/devices/$DeviceID/profiles"
    if(($Global:OAuthtimer1.Elapsed.TotalMinutes -gt 55) -or ($null -eq $Global:OAuthtimer1)){
        Write-Log "OAuth token expiring within 5 min or doesn't exist, renewing..."
        $global:header_v1 = Get-Header -version 1
    }
    $Profiles = (Invoke-RestMethod -Method GET -Uri $Uri -ContentType "application/json" -Header $global:header_v1).DeviceProfiles | Select Name, @{Name = 'ProfileId'; Expression = { $_.id.value } }, Status
    $Profiles
}

#$deviceprofile = Get-ProfileStatus -Deviceid $_.DeviceID