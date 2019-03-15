function global:Invoke-AuthenticateMatterMost($Username, $UserPass) {
  $loginURI = $global:MatterMostRootUri + '/api/v4/users/login'

  $r = Invoke-WebRequest -URI $loginURI -Method POST -Body (@{ "login_id" = $Username; "password" = $UserPass } | ConvertTo-JSON) -UseBasicParsing -ContentType 'application/json'
  $authUser = $r.Content | ConvertFrom-JSON
  # Add the AuthToken
  $authUser | Add-Member -MemberType NoteProperty -Name "apitoken" -Value $r.Headers.Token| Out-Null

  Write-Output $authUser
}

Function global:Invoke-MattermostAPI($ScenarioUser, $URI, $Method, $Body) {
  $iwrProps = @{
    'URI' = $global:MatterMostRootUri + '/api/v4/' + $URI
    'UseBasicParsing' = $true
    'Method' = $Method
  }

  if ($Method -eq "POST") {
    $iwrProps['Body'] = ($Body | ConvertTo-JSON -Depth 10 -Compress)
  }

  $headers = @{
    'Authorization' = "Bearer $($ScenarioUser.apitoken)"
  }

  Invoke-RestMethod @iwrProps -Headers $headers -ErrorAction Stop
}

Function global:Get-UserInformation($Username, $UserPass) {
  $authUser = Invoke-AuthenticateMatterMost -Username $Username -UserPass $UserPass

  # Get the Team ID
  $r = Invoke-MattermostAPI -ScenarioUser $authUser -Uri "users/$($authUser.id)/teams" -Method GET | Select-Object -First 1
  $authUser | Add-Member -MemberType NoteProperty -Name "teamid" -Value $r.id | Out-Null
  # Get the Channel ID
  $r = (Invoke-MattermostAPI -ScenarioUser $authUser -Uri "users/$($authUser.id)/teams/$($authUser.teamid)/channels" -Method GET) | Where-Object { $_.display_name -eq 'Town Square' }
  $authUser | Add-Member -MemberType NoteProperty -Name "channelid" -Value $r.id

  Write-Output $authUser
}

#---- Gherkin functions

Given 'mattermost server (?<uri>.+)' {
  param($uri)
  $global:MatterMostRootUri = $uri

  $true | Should -Be $true
}

Given "mattermost user '(?<user>.+)' with passsword '(?<pass>.+)'" {
  param($user, $pass)

  $script:senarioUser = Get-UserInformation -Username $user -UserPass $pass
  $script:originalMessage = $null
  $script:senarioUser.email | Should -Be $user
}

When "sending a message of (?<message>.+)" {
  param($message)
  $body = @{
    'channel_id' = $script:senarioUser.channelid
    'message' = $message
  }
  $script:originalMessage = Invoke-MattermostAPI -ScenarioUser $script:senarioUser -Uri 'posts' -Method POST -Body $body

  $true | Should -Be $true
}

Given 'waiting (?<delay>\d+) seconds' {
  param($delay)

  Start-Sleep -Seconds ([Int]$delay)
  $true | Should -Be $true
}

Then 'the message should have a reaction of (?<reaction>.+)' {
  param($reaction)
  $updatedMessage = Invoke-MattermostAPI -ScenarioUser $script:senarioUser -Uri "posts/$($script:originalMessage.id)" -Method GET

  # The Bot should have a reaction on the message
  $updatedMessage.metadata.reactions.Count | Should -BeGreaterThan 0
  $updatedMessage.metadata.reactions[0].emoji_name | Should -Be $reaction
}

Then 'poshbot returns a message that (?<matchType>starts with|contains) (?<message>.+)' {
  param($matchType, $message)
  $newMessages = Invoke-MattermostAPI -ScenarioUser $script:senarioUser -Uri "channels/$($script:senarioUser.channelid)/posts?after=$($script:originalMessage.id)" -Method GET

  # There should only be one new message
  $newMessages.order.Count | Should -Be 1
  $newPostID = $newMessages.order[0]
  $newPost = $newMessages.posts."$newPostID"

  if ($matchType -eq 'starts with') {
    # The message text should start with...
    $newPost.message | Should -Match "^$message"
  }

  if ($matchType -eq 'contains') {
    # The message text should start with...
    $newPost.message | Should -Match "$message"
  }
}
