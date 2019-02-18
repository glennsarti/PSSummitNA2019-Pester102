$VerbosePreference = 'Continue'

Function Invoke-MatterMost{
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$False,ValueFromRemainingArguments=$True)]
    [Object[]] $Arguments
  )
  & docker exec -it mattermost-preview $Arguments
}
New-Alias -Name mm -Value Invoke-MatterMost

Function Invoke-MattermostAPI($URI, $Method, $Body) {
  $iwrProps = @{
    'URI' = $Endpoint + '/api/v4/' + $URI
    'UseBasicParsing' = $true
    'Method' = $Method
  }

  if ($Method -eq "POST") {
    $iwrProps['Body'] = ($Body | ConvertTo-JSON -Depth 10 -Compress)
  }

  $headers = @{
    'Authorization' = "Bearer $APIToken"
  }

  Write-Host ($headers | Out-String)
  $result = Invoke-RestMethod @iwrProps -Headers $headers

  $result
}

Function Invoke-SpinWaitMattermost {
  $SpinStart = Get-Date

  do {
    $loop = $false
    try {
      $result = Invoke-WebRequest http://localhost:8065 -UseBasicParsing
      If ($result.StatusCode -ne 200) { Throw "Not yet ready"}
    } catch {
      Start-Sleep -Seconds 2
      Write-Verbose "Spinwait Error $_"
      $loop = $true
    }
    $Duration = ((Get-Date) - $SpinStart).Seconds
  } while ($loop -and ($Duration -le 30))

}

Write-Verbose "Clearing out old container..."
& docker stop mattermost-preview
& docker rm mattermost-preview

Write-Verbose "Starting Mattermost Server..."
& docker run --name mattermost-preview -d --publish 8065:8065 --add-host dockerhost:127.0.0.1 `
  --env 'MM_SERVICESETTINGS_SITEURL=http://localhost:8056' `
  --env MM_LOGSETTINGS_CONSOLELEVEL=ERROR `
  --env MM_LOGSETTINGS_FILELEVEL=DEBUG `
  --env MM_SERVICESETTINGS_ENABLEUSERACCESSTOKENS=true `
  mattermost/mattermost-preview

Write-Verbose "Configuring MM container insitu..."
mm mkdir ./client
mm mkdir ./client/plugins

Invoke-SpinWaitMattermost

mm mattermost @mmdir user create --firstname Posh --lastname Bot --email poshbot@example.com --username poshbot --password Password1
mm mattermost @mmdir user create --firstname user002 --lastname test --email user2@example.com --username user2 --password Password1
mm mattermost @mmdir user create --firstname user003 --lastname test --email user3@example.com --username user3 --password Password1

mm mattermost @mmdir team create --name testteam --display_name "Test Team"
mm mattermost @mmdir team add testteam poshbot@example.com user2@example.com user3@example.com

mm mattermost @mmdir channel add testteam:town-square poshbot@example.com user2@example.com user3@example.com

Write-Verbose "Adding Admin Users..."
mm mattermost @mmdir roles system_admin poshbot@example.com


Write-Verbose "Doing online setup..."
$EndPoint = 'http://localhost:8065'
$loginURI = $EndPoint + '/api/v4/users/login'
# Authenticate...
$r = Invoke-WebRequest -URI $loginURI -Method POST -Body (@{ "login_id" = 'poshbot@example.com'; "password" ='Password1' } | ConvertTo-JSON) -UseBasicParsing -ContentType 'application/json'
$APIToken = $r.Headers.Token
$LoginData = $r.Content | ConvertFrom-JSON


# Create Personal Access Token for the bot
$body = @{ 'description' = 'Automated PAT creation' }
$result = Invoke-MattermostAPI -Uri "users/$($LoginData.id)/tokens" -Method 'POST' -Body $body
$BotToken = $result.Token

Write-Host "BOT TOKEN IS $BotToken"

Write-Verbose "Mattermost is now running ..."
mm mattermost @mmdir version
