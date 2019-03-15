Function Stop-MattermostServer {
  Write-Verbose "Stopping mattermost container..."
  & docker stop mattermost-preview | Out-Null
  Write-Verbose "Removing mattermost container..."
  & docker rm mattermost-preview | Out-Null
}

Function Stop-PoshBot {
  $runBotScript = Resolve-Path "$PSScriptRoot/Pre-RunBot.ps1"

  $botProcess = Get-WmiObject Win32_Process | `
    Where-Object { $_.Name -eq 'powershell.exe' } | `
    Where-Object { $_.CommandLine -like "*${runBotScript}*" } | Select -First 1

  if ($null -eq $botProcess) {
    Write-Verbose "PoshBot process is not running"
  } else {
    Write-Verbose "Killing PoshBot process $($botProcess.ProcessId)"
    Stop-Process -Id $botProcess.ProcessId -Force -Confirm:$false | Out-Null
  }
}

Stop-MattermostServer
Stop-PoshBot
