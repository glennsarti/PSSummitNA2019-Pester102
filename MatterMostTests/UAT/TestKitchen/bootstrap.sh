#!/bin/bash

# Test Kitchen isn't smart enough to know that, HEY YOU CAN RUN POWERSHELL ON NON-WINDOWS!
# So we need to embed the PowerShell script in a Bash script. Sad, but hey, this is all we have.
# - Remember to escape the dollar signs

cat > /tmp/bootstrap.ps1 <<- EOM
\$ErrorActionPreference = 'Stop'
\$logFile = '/tmp/mmbot/PoshBot.log'

Function Invoke-SpinWaitPoshBot(\$logFilePath) {
  Write-Host "Waiting 60 seconds for PoshBot to start..."
  \$Timeout = (Get-Date).AddSeconds(60)
  \$PoshBotRunning = \$false

  do {
    if (Test-Path -Path \$logFile) {
      # We may get file lock contention here, so just ignore errors
      \$content = ""
      \$content = Get-Content -Path \$logFile -Raw -Force:\$true -ErrorAction SilentlyContinue

      \$PoshBotRunning = (\$Content -Match '\"Message\":\"Beginning message processing loop\"')
    }
    if (-not \$PoshBotRunning) { Write-Host "Sleeping for a moment..." }
    Start-Sleep -Seconds 5
  } while ((-not \$PoshBotRunning) -and ([System.DateTime]::Now -lt \$Timeout))

  Write-Output \$PoshBotRunning
}

Write-Host "Waiting for PoshBot to connect succesfully to Mattermost..."
\$running = Invoke-SpinWaitPoshBot -logFilePath \$logFile

if (-not \$running) {
  Write-Host "Poshbot did not start in time!"
  Throw "Poshbot did not start in time"
} else {
  Write-Host "PoshBot is now listening."
}
EOM

pwsh -NoProfile -NonInteractive -NoLogo -File /tmp/bootstrap.ps1

# MAJOR HACK There's something screwy in the verifier and it creates the directory as a file.  Just precreate to stop it
if [ -f "/tmp/verifier" ]; then
  rm -f /tmp/verifier
fi
if [ ! -d "/tmp/verifier" ]; then
  mkdir /tmp/verifier
  chmod 777 /tmp/verifier
fi
