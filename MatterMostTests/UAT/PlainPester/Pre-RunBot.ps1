param(
  $Token,
  $ApiUri = 'http://localhost:8065'
)

# Import necessary modules
$moduleRoot = Resolve-Path -Path "$PSScriptRoot/../../../PoshBot.Mattermost.Backend"

Import-Module PoshBot
. "$moduleRoot\build.ps1" clean
. "$moduleRoot\build.ps1" compile
Import-Module "$moduleRoot\out\PoshBot.Mattermost.Backend\0.0.1\PoshBot.Mattermost.Backend.psd1"

# Store config path in variable
$tmpPath = "$moduleRoot\tmp\mm"
$configPath = "$tmpPath\MMConfig.psd1"

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
    Token  = $Token
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
