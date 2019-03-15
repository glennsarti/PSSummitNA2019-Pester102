Function Invoke-SetupMatterMost{
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$False,ValueFromRemainingArguments=$True)]
    [Object[]] $Arguments
  )
  & docker exec -it mattermost-preview $Arguments | Out-Null
}
New-Alias -Name mm -Value Invoke-SetupMatterMost

Function Invoke-SetupMattermostAPI($URI, $Method, $Body) {
  $iwrProps = @{
    'URI' = $Endpoint + '/api/v4/' + $URI
    'UseBasicParsing' = $true
    'Method' = $Method
  }

  if ($Method -eq "POST") {
    $iwrProps['Body'] = ($Body | ConvertTo-JSON -Depth 10 -Compress)
  }

  $headers = @{
    'Authorization' = "Bearer $global:APIToken"
  }

  $result = Invoke-RestMethod @iwrProps -Headers $headers

  $result
}

Function Invoke-SpinWaitMattermost {
  $SpinStart = Get-Date

  do {
    $loop = $false
    try {
      $result = Invoke-WebRequest http://localhost:8065 -UseBasicParsing -Verbose:$false
      If ($result.StatusCode -ne 200) { Throw "Not yet ready"}
    } catch {
      Start-Sleep -Seconds 2
      Write-Verbose "Spinwait Error $_"
      $loop = $true
    }
    $Duration = ((Get-Date) - $SpinStart).Seconds
  } while ($loop -and ($Duration -le 30))
}

Function Start-MattermostServer {
  Write-Verbose "Clearing out old container..."
  & docker stop mattermost-preview | Out-Null
  & docker rm mattermost-preview | Out-Null

  Write-Verbose "Starting Mattermost Server..."
  & docker run --name mattermost-preview -d --publish 8065:8065 --add-host dockerhost:127.0.0.1 `
    --env 'MM_SERVICESETTINGS_SITEURL=http://localhost:8056' `
    --env MM_LOGSETTINGS_CONSOLELEVEL=ERROR `
    --env MM_LOGSETTINGS_FILELEVEL=DEBUG `
    --env MM_SERVICESETTINGS_ENABLEUSERACCESSTOKENS=true `
    mattermost/mattermost-preview | Out-Null

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
  $global:APIToken = $r.Headers.Token
  $LoginData = $r.Content | ConvertFrom-JSON


  # Create Personal Access Token for the bot
  $body = @{ 'description' = 'Automated PAT creation' }
  $result = Invoke-SetupMattermostAPI -Uri "users/$($LoginData.id)/tokens" -Method 'POST' -Body $body
  $global:BotToken = $result.Token

  #Write-Host "BOT TOKEN IS $global:BotToken"

  Write-Verbose "Mattermost is now running ..."
  mm mattermost @mmdir version
}

function Start-PoshBot {
  $runBotScript = Resolve-Path "$PSScriptRoot/Pre-RunBot.ps1"

  $startInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
  $startInfo.Arguments = @('-NoLogo', '-NonInteractive', '-NoProfile', '-File', "`"$runBotScript`"", '-Token', $global:BotToken)
  $startInfo.CreateNoWindow = $false
  $startInfo.FileName = 'powershell.exe'
  $startInfo.WorkingDirectory = $PSScriptRoot

  [System.Diagnostics.Process]::Start($startInfo)
}

Function Invoke-SpinWaitPoshBot($logFilePath) {
  Write-Verbose "Waiting 30 seconds for PoshBot to start..."
  $Timeout = (Get-Date).AddSeconds(30)
  $PoshBotRunning = $false

  do {
    if (Test-Path -Path $logFile) {
      # We may get file lock contention here, so just ignore errors
      $content = ""
      $content = Get-Content -Path $logFile -Raw -Force:$true -ErrorAction SilentlyContinue

      $PoshBotRunning = ($Content -Match '\"Message\":\"Beginning message processing loop\"')
    }
    if (-not $PoshBotRunning) { Write-Verbose "Sleeping and will try again" }
    Start-Sleep -Seconds 2
  } while ((-not $PoshBotRunning) -and ([System.DateTime]::Now -lt $Timeout))

  Write-Output $PoshBotRunning
}

$moduleRoot = Resolve-Path -Path "$PSScriptRoot/../../../PoshBot.Mattermost.Backend"
$logFile = Join-Path -Path $moduleRoot -ChildPath '/tmp/mm/PoshBot.log'

Write-Verbose "Start the Mattermost Server ..."
Start-MattermostServer

Write-Verbose "Start PoshBot..."
If (Test-Path -Path $logFile) { Remove-Item -Path $logFile -Force -Confirm:$false | Out-Null }
$result = Start-PoshBot
Write-Verbose "Poshbot is running as process $($result.Id)"

Write-Verbose "Waiting for PoshBot to connect succesfully to Mattermost..."
$running = Invoke-SpinWaitPoshBot -logFilePath $logFile

if (-not $running) {
  Write-Verbose "Poshbot did not start in time!"
  Throw "Poshbot did not start in time"
} else {
  Write-Verbose "PoshBot is now listening."
}
