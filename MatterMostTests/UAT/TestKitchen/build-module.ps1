$ErrorActionPreference = 'Stop'
# Install the required modules...
@('Pester', 'psake', 'BuildHelpers') | ForEach-Object {
  $moduleName = $_

  $theModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq $moduleName } | Select-Object -First 1
  if ($null -eq $theModule) {
    Write-Host "Installing $moduleName module..."
    Install-Module -Name $moduleName -Repository PSGallery -Scope CurrentUser -AllowClobber -Force -Confirm:$false -ErrorAction Stop -SkipPublisherCheck
  }
  Import-Module -Name $moduleName -Verbose:$false -Force -ErrorAction Stop
}

$moduleRoot = Resolve-Path -Path "$PSScriptRoot/../../../PoshBot.Mattermost.Backend"

. "$moduleRoot\build.ps1" clean
. "$moduleRoot\build.ps1" compile

Write-Host "Copying Assets..."
Copy-Item -Path "$moduleRoot\out\PoshBot.Mattermost.Backend\0.0.1\PoshBot.Mattermost.Backend.psd1" -Dest "$PSScriptRoot\PoshBot.Mattermost.Backend.psd1" -Force -Confirm:$false
Copy-Item -Path "$moduleRoot\out\PoshBot.Mattermost.Backend\0.0.1\PoshBot.Mattermost.Backend.psm1" -Dest "$PSScriptRoot\PoshBot.Mattermost.Backend.psm1" -Force -Confirm:$false
