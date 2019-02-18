# Function Send-MattermostEvent {
#   [cmdletbinding()]
#     param (
#       [Parameter(Mandatory)]
#       [Hashtable]$message,

#       [Switch]$Wait,

#       [Parameter(Mandatory)]
#       [Object]$WebSocket
#     )

#     Process {
#       Write-Warning "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!44444"
#       Write-Error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!44444"
#       Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!44444"
#       Throw "WHAT THE F IS HAPPENEING"

#   }
# }

# [void]SendMattermostEvent([Hashtable]$message, [bool]$Wait) {
#   if ($this.WebSocket.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
#     $this.LogInfo([LogSeverity]::Error, "Unable to send Mattermost event as websocket is closed")
#     return
#   }

#   $EventSendTimeout = 30

#   $msgText = $message | ConvertTo-JSON -Depth 10

# Write-Host $msgText -ForegroundColor Red

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