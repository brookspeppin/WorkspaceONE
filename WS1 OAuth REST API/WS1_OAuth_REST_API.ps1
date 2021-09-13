<#	
	.NOTES
	===========================================================================
	 Created on:   	9/7/2021
	 Created by:   	Brooks Peppin, www.brookspeppin.com
	 ==========================================================================
	.DESCRIPTION
		Sample script for using REST API in Workspace ONE. From Blog https://www.brookspeppin.com/2021/07/24/rest-api-in-workspace-one-uem/
#>


$server = "https://cnXXXX.awmdm.com"

#Setup OAuth account by going to UEM > Configurations > Search for "OAuth" > Click on OAuth Client. Create a new one.
$client_id = "enter your own client id"
$client_secret = "enter your own client secret"
$access_token_url = "https://na.uemauth.vmwservices.com/connect/token"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $client_id
    client_secret = $client_secret
}

try {
    $response = Invoke-WebRequest -Method Post -Uri $access_token_url -Body $body -UseBasicParsing
    $response = $response | ConvertFrom-Json
    $oauth_token = [string]$($response.access_token)

}
catch {
    $ErrorMessage = $PSItem | ConvertFrom-Json
    Write-Log "Failed to create OAuth Token for: $env with following ErrorCode: $($ErrorMessage.errorCode) - $($ErrorMessage.message)" -ForegroundColor Red
}

$header_v1 = @{
    "Authorization" = "Bearer " + $oauth_Token;
    "Accept" = "application/json;version=1";
    "Content-Type" = "application/json"
}

$header_v2 = @{
    "Authorization" = "Bearer " + $oauth_Token;
    "Accept" = "application/json;version=2";
    "Content-Type" = "application/json"
}

#Devices
$devices = Invoke-RestMethod -Uri "$server/api/mdm/devices/search?" -Method Get -Headers $header_v1
$devices.Devices.SerialNumber

Invoke-RestMethod -Uri "$server/api/mdm/devices/search?" -Method Get -Headers $header_v1