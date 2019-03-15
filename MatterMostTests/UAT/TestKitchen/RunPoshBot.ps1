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
      Write-Host "Spinwait Error $_"
      $loop = $true
    }
    $Duration = ((Get-Date) - $SpinStart).Seconds
  } while ($loop -and ($Duration -le 120))
}

Set-Location '/mm'

if (-not(Test-Path -Path 'client')) {
  Write-Host "Creating client directory..."
  New-Item 'client' -ItemType Directory | Out-Null
} else { Write-Host 'client directory exists' }
if (-not(Test-Path -Path 'client/plugins')) {
  Write-Host "Creating plugins directory..."
  New-Item 'client/plugins' -ItemType Directory | Out-Null
} else { Write-Host 'client/plugins directory exists' }

Write-Host "Waiting for Mattermost Server to be running..."
Invoke-SpinWaitMattermost
Write-Host "Mattermost Server is running"

Write-Host 'Creating users...'

# It's "safe" to call these over and over again. It'll just throw errors
& mattermost user create --firstname Posh --lastname Bot --email poshbot@example.com --username poshbot --password Password1
& mattermost user create --firstname user002 --lastname test --email user2@example.com --username user2 --password Password1
& mattermost user create --firstname user003 --lastname test --email user3@example.com --username user3 --password Password1

& mattermost team create --name testteam --display_name "Test Team"
& mattermost team add testteam poshbot@example.com user2@example.com user3@example.com

& mattermost channel add testteam:town-square poshbot@example.com user2@example.com user3@example.com

Write-Host "Adding Admin Users..."
& mattermost roles system_admin poshbot@example.com

Write-Host "Doing online setup..."
$EndPoint = 'http://localhost:8065'
$loginURI = $EndPoint + '/api/v4/users/login'
# Authenticate...
$r = Invoke-WebRequest -URI $loginURI -Method POST -Body (@{ "login_id" = 'poshbot@example.com'; "password" ='Password1' } | ConvertTo-JSON) -UseBasicParsing -ContentType 'application/json'
$global:APIToken = $r.Headers.Token
$LoginData = $r.Content | ConvertFrom-JSON

If (Test-Path -Path 'bot-token.txt') {
  Write-Host "Reading PAT for the bot"
  $global:BotToken = (Get-Content 'bot-token.txt' -Raw).Trim()
} else {
  Write-Host "Creating PAT for the bot"
  # Create Personal Access Token for the bot
  $body = @{ 'description' = 'Automated PAT creation ' + (Get-Date).ToString('s') }
  $result = Invoke-SetupMattermostAPI -Uri "users/$($LoginData.id)/tokens" -Method 'POST' -Body $body
  $global:BotToken = $result.Token

  $global:BotToken | Set-Content 'bot-token.txt'
}

Write-Host "BOT TOKEN IS $global:BotToken"

Write-Host "Mattermost is now running ..."
# & mattermost version

$ApiUri = 'http://localhost:8065'

# Import necessary modules
Import-Module Poshbot
Import-Module ".\PoshBot.Mattermost.Backend.psd1"

# Store config path in variable
$tmpPath = "/tmp/mmbot"
If (-not(Test-Path -Path $tmpPath)) { New-Item -ItemType Directory -Path $tmpPath | Out-Null}
$configPath = "$tmpPath/MMConfig.psd1"

# Create hashtable of parameters for New-PoshBotConfiguration
$botParams = @{
  # The friendly name of the bot instance
  Name                   = 'MMMBop'
  # The primary email address(es) of the admin(s) that can manage the bot
  BotAdmins              = @('user2')
  # Universal command prefix for PoshBot.
  # If the message includes this at the start, PoshBot will try to parse the command and
  # return an error if no matching command is found
  CommandPrefix          = '!'
  # PoshBot log level.
  LogLevel               = 'Debug'
  # The path containing the configuration files for PoshBot
  ConfigurationDirectory = "$tmpPath"
  # The path where you would like the PoshBot logs to be created
  LogDirectory           = "$tmpPath"
  # The path containing your PoshBot plugins
  PluginDirectory        = "$tmpPath\Plugins"

  BackendConfiguration   = @{
    Token  = $global:BotToken
    ApiUri = $ApiUri
    Name   = 'MattermostBackend'
  }
}

Get-ChildItem $tmpPath -Filter *.log* | Remove-Item -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

# Create the bot backend
$backend = New-PoshBotMatterMostBackend -Configuration $botParams.BackendConfiguration

# Create the bot configuration
$myBotConfig = New-PoshBotConfiguration @botParams

# Save bot configuration
Save-PoshBotConfiguration -InputObject $myBotConfig -Path $configPath -Force

# Create the bot instance from the backend and configuration path
$bot = New-PoshBotInstance -Backend $backend -Path $configPath

# Start the bot
$bot | Start-PoshBot
