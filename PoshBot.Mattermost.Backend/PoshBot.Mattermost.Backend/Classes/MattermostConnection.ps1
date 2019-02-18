class MattermostConnection : Connection {
  [System.Net.WebSockets.ClientWebSocket]$WebSocket
  [pscustomobject]$LoginData
  [string]$UserName
  [string]$Domain
  [string]$WebSocketUrl
  [bool]$Connected
  [object]$ReceiveJob = $null
  [string]$BotTeamID

  MattermostConnection() {
      $this.WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
      $this.WebSocket.Options.KeepAliveInterval = 5
  }

  # Connect to Slack and start receiving messages
  [void]Connect() {
    if ($null -eq $this.ReceiveJob -or $this.ReceiveJob.State -ne 'Running') {
      $this.LogDebug('Connecting to Mattermost Real Time API')
      $this.RtmConnect()
      $this.StartReceiveJob()
    } else {
      $this.LogDebug([LogSeverity]::Warning, 'Receive job is already running')
    }
  }

  [object]InvokeMattermostAPI($Uri, $Method, $Body) {
    $iwrProps = @{
      'URI' = $this.Config.Endpoint + '/api/v4/' + $URI
      'Method' = $Method
    }

    if ($Method -eq "POST") {
      $iwrProps['Body'] = ($Body | ConvertTo-JSON -Depth 10 -Compress)
    }

    $headers = @{
      'Authorization' = "Bearer " + $this.Config.Credential.GetNetworkCredential().Password
    }

    $this.LogDebug([LogSeverity]::Debug, "Sending to uri ${Uri} using ${Method}: $($iwrProps['Body'])")
    $result = Invoke-RestMethod @iwrProps -Headers $headers

    return $result
  }

  # Log in to Mattermost with the bot token and get a URL to connect to via websockets
  [void]RtmConnect() {
    $loginURI = $this.Config.Endpoint + '/api/v4/users/login'
    $token = $this.Config.Credential.GetNetworkCredential().Password

    try {
      # Get who am I
      $this.LoginData = $this.InvokeMattermostAPI('users/me', "Get", @{})
      # Get my team - Special Version - First team listed - THIS IS FRAGILE!!
      $this.BotTeamID = $this.InvokeMattermostAPI('teams', "Get", @{})[0].id

      $this.LogInfo([LogSeverity]::Info, 'Successfully authenticated to Mattermost API')
      # TODO This is super dodgey!!
      $this.WebSocketUrl = $this.Config.Endpoint.replace('http:', 'ws:') + '/api/v4/websocket'
    } catch {
      $this.LogInfo([LogSeverity]::Error, 'Error connecting to Mattermost Real Time API', [ExceptionFormatter]::Summarize($_))
    }
  }

  # [void]SendMattermostEvent([Hashtable]$message, [bool]$Wait) {
  #   if ($this.WebSocket.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
  #     $this.LogInfo([LogSeverity]::Error, "Unable to send Mattermost event as websocket is closed")
  #     return
  #   }

  #   $EventSendTimeout = 30

  #   $msgText = $message | ConvertTo-JSON -Depth 10

  #   $buffer = $this.Encoder.GetBytes($msgText);
  #   $as = New-Object System.ArraySegment[byte]  -ArgumentList @(,$buffer)

  #   $result = $this.WebSocket.SendAsync($as, [System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, [System.Threading.CancellationToken]::None)
  #   $SendStart = Get-Date

  #   if (!$Wait) {
  #     return
  #   }

  #   While (!$result.IsCompleted) {
  #     $TimeTaken = ((Get-Date) - $SendStart).Seconds
  #     If ($TimeTaken -gt $EventSendTimeout) {
  #       $this.LogInfo([LogSeverity]::Error, "Message took longer than $EventSendTimeout seconds and may not have been sent.")
  #       return
  #     }
  #     Start-Sleep -Milliseconds 100
  #   }
  # }

  # Setup the websocket receive job
  [void]StartReceiveJob() {
    $recv = {
          [cmdletbinding()]
          param(
              [parameter(mandatory)]
              $url,

              [parameter(mandatory)]
              [String]$MattermostToken
          )

          # Connect to websocket
          Write-Verbose "[MattermostBackend:ReceiveJob] Connecting to websocket at [$($url)]"
          [System.Net.WebSockets.ClientWebSocket]$webSocket = New-Object System.Net.WebSockets.ClientWebSocket
          $cts = New-Object System.Threading.CancellationTokenSource
          $task = $webSocket.ConnectAsync($url, $cts.Token)
          do { Start-Sleep -Milliseconds 100 }
          until ($task.IsCompleted)

          Function Send-MattermostEvent {
            [cmdletbinding()]
            param (
              [Parameter(Mandatory)]
              [Hashtable]$message,

              [Switch]$Wait,

              [Parameter(Mandatory)]
              [Object]$WebSocket
            )

            Process {
              $EventSendTimeout = 30
              $msgText = $message | ConvertTo-JSON -Compress -Depth 10
              $encoder = New-Object System.Text.UTF8Encoding
              $buffer = $encoder.GetBytes($msgText);
              $as = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
              $result = $WebSocket.SendAsync($as, [System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, [System.Threading.CancellationToken]::None)
              $SendStart = Get-Date
              if (!$Wait) {
                return
              }
              While (!$result.IsCompleted) {
                $TimeTaken = ((Get-Date) - $SendStart).Seconds
                If ($TimeTaken -gt $EventSendTimeout) {
                  $this.LogInfo([LogSeverity]::Error, "Message took longer than $EventSendTimeout seconds and may not have been sent.")
                  return
                }
                Start-Sleep -Milliseconds 100
              }
              $this.LogInfo([LogSeverity]::Debug, "Message took $TimeTaken seconds to send")
            }
          }

          # Send the initial authentication challenge
          Write-Verbose "[MattermostBackend:ReceiveJob] Sending authentication challenge"
          $msg = @{
            'seq' = 1
            'action' = 'authentication_challenge'
            'data' = @{
              'token' = $MattermostToken
            }
          }
          Send-MattermostEvent -Message $msg -Wait -WebSocket $webSocket

          # Receive messages and put on output stream so the backend can read them
          [ArraySegment[byte]]$buffer = [byte[]]::new(4096)
          $taskResult = $null
          while ($webSocket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            do {
              $taskResult = $webSocket.ReceiveAsync($buffer, [System.Threading.CancellationToken]::None)
              while (-not $taskResult.IsCompleted) {
                Start-Sleep -Milliseconds 100
              }
            } until ($taskResult.Result.Count -lt 4096)
            $jsonResult = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $taskResult.Result.Count)

# Write-Host "!!!!!!!!!!!!!!!!"
# Write-Host "JSON DATA = $jsonResult" -ForegroundColor Gr
# Write-Host "!!!!!!!!!!!!!!!!"

            if (-not [string]::IsNullOrEmpty($jsonResult)) {
              $jsonResult
            }
          }
          $socketStatus = [pscustomobject]@{
            State = $webSocket.State
            CloseStatus = $webSocket.CloseStatus
            CloseStatusDescription = $webSocket.CloseStatusDescription
          }
          $socketStatusStr = ($socketStatus | Format-List | Out-String).Trim()
          Write-Warning -Message "Websocket state is [$($webSocket.State.ToString())].`n$socketStatusStr"
      }
      try {
        $this.ReceiveJob = Start-Job -Name ReceiveRtmMessages -ScriptBlock $recv -ArgumentList $this.WebSocketUrl,$this.Config.Credential.GetNetworkCredential().Password -ErrorAction Stop -Verbose
        $this.Connected = $true
        $this.Status = [ConnectionStatus]::Connected
        $this.LogInfo("Started websocket receive job [$($this.ReceiveJob.Id)]")
      } catch {
        $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
      }
  }

  # Read all available data from the job
  [string]ReadReceiveJob() {
    # Read stream info from the job so we can log them
    $infoStream = $this.ReceiveJob.ChildJobs[0].Information.ReadAll()
    $warningStream = $this.ReceiveJob.ChildJobs[0].Warning.ReadAll()
    $errStream = $this.ReceiveJob.ChildJobs[0].Error.ReadAll()
    $verboseStream = $this.ReceiveJob.ChildJobs[0].Verbose.ReadAll()
    $debugStream = $this.ReceiveJob.ChildJobs[0].Debug.ReadAll()
    foreach ($item in $infoStream) {
      $this.LogInfo($item.ToString())
    }
    foreach ($item in $warningStream) {
      $this.LogInfo([LogSeverity]::Warning, $item.ToString())
    }
    foreach ($item in $errStream) {
      $this.LogInfo([LogSeverity]::Error, $item.ToString())
    }
    foreach ($item in $verboseStream) {
      $this.LogVerbose($item.ToString())
    }
    foreach ($item in $debugStream) {
      $this.LogVerbose($item.ToString())
    }

    # The receive job stopped for some reason. Reestablish the connection if the job isn't running
    if ($this.ReceiveJob.State -ne 'Running') {
      $this.LogInfo([LogSeverity]::Warning, "Receive job state is [$($this.ReceiveJob.State)]. Attempting to reconnect...")
      Start-Sleep -Seconds 5
      $this.Connect()
    }

    if ($this.ReceiveJob.HasMoreData) {
      return $this.ReceiveJob.ChildJobs[0].Output.ReadAll()
    } else {
      return $null
    }
  }

  # Stop the receive job
  [void]Disconnect() {
    $this.LogInfo('Closing websocket')
    if ($this.ReceiveJob) {
      $this.LogInfo("Stopping receive job [$($this.ReceiveJob.Id)]")
      $this.ReceiveJob | Stop-Job -Confirm:$false -PassThru | Remove-Job -Force -ErrorAction SilentlyContinue
    }
    $this.Connected = $false
    $this.Status = [ConnectionStatus]::Disconnected
  }
}