param (
  $MatterMostRoot = "http://localhost:8065",
  $loginID = 'user2@example.com',
  $loginPassword = 'Password1'
)

function Invoke-AuthenticateMatterMost() {
  $loginURI = $MatterMostRoot + '/api/v4/users/login'
  $r = Invoke-WebRequest -URI $loginURI -Method POST -Body (@{ "login_id" = $loginID; "password" = $loginPassword } | ConvertTo-JSON) -UseBasicParsing -ContentType 'application/json'
  $Script:LoginData = $r.Content | ConvertFrom-JSON
  $Script:APIToken = $r.Headers.Token

  $Script:APIToken
}

Function Invoke-MattermostAPI($URI, $Method, $Body) {
  $iwrProps = @{
    'URI' = $MatterMostRoot + '/api/v4/' + $URI
    'UseBasicParsing' = $true
    'Method' = $Method
  }

  if ($Method -eq "POST") {
    $iwrProps['Body'] = ($Body | ConvertTo-JSON -Depth 10 -Compress)
  }

  if ($null -eq $Script:APIToken) { Invoke-AuthenticateMatterMost }

  $headers = @{
    'Authorization' = "Bearer $Script:APIToken"
  }

  $result = Invoke-RestMethod @iwrProps -Headers $headers -ErrorAction Stop

  $result
}

Function Get-UserInformation {
  if ($null -eq $Script:LoginData) {
    Invoke-AuthenticateMatterMost | Out-Null
    # Get the Team ID
    $r = Invoke-MattermostAPI -Uri "users/$($Script:LoginData.id)/teams" -Method GET | Select-Object -First 1
    $Script:LoginData | Add-Member -MemberType NoteProperty -Name "teamid" -Value $r.id | Out-Null
    # Get the Channel ID
    $r = Invoke-MattermostAPI -Uri "users/$($Script:LoginData.id)/teams/$($Script:LoginData.teamid)/channels" -Method GET | Where-Object { $_.display_name -eq 'Town Square' }
    $Script:LoginData | Add-Member -MemberType NoteProperty -Name "channelid" -Value $r.id

  }
  $Script:LoginData
}

Describe "Positive Message Tests" {
  it "should respond to '! help'" {
    $userInfo = Get-UserInformation

    # Post a Message
    $body = @{
      'channel_id' = $userInfo.channelid
      'message' = "! help"
    }
    $originalMessage = Invoke-MattermostAPI -Uri 'posts' -Method POST -Body $body

    # Give the bot time to respond
    Start-Sleep 3
    $updatedMessage = Invoke-MattermostAPI -Uri "posts/$($originalMessage.id)" -Method GET

    # The Bot should have a reaction on the message
    $updatedMessage.metadata.reactions.Count | Should -BeGreaterThan 0
    $updatedMessage.metadata.reactions[0].emoji_name | Should -Be 'white_check_mark'

    $newMessages = Invoke-MattermostAPI -Uri "channels/$($userInfo.channelid)/posts?after=$($originalMessage.id)" -Method GET

    # There should only be one new message
    $newMessages.order.Count | Should -Be 1
    $newPostID = $newMessages.order[0]
    $newPost = $newMessages.posts."$newPostID"

    # The message text should start with...
    $newPost.message | Should -Match "```````nFullCommandName"
  }

  it "should respond to '! help commanddoesntexist'" {
    $userInfo = Get-UserInformation

    # Post a Message
    $body = @{
      'channel_id' = $userInfo.channelid
      'message' = "! help commanddoesntexist"
    }
    $originalMessage = Invoke-MattermostAPI -Uri 'posts' -Method POST -Body $body

    # Give the bot time to respond
    Start-Sleep 3
    $updatedMessage = Invoke-MattermostAPI -Uri "posts/$($originalMessage.id)" -Method GET

    # The Bot should have a reaction on the message
    $updatedMessage.metadata.reactions.Count | Should -BeGreaterThan 0
    $updatedMessage.metadata.reactions[0].emoji_name | Should -Be 'white_check_mark'

    $newMessages = Invoke-MattermostAPI -Uri "channels/$($userInfo.channelid)/posts?after=$($originalMessage.id)" -Method GET

    # There should only be one new message
    $newMessages.order.Count | Should -Be 1
    $newPostID = $newMessages.order[0]
    $newPost = $newMessages.posts."$newPostID"

    # The message text should start with...
    $newPost.message | Should -Match "No commands found matching \[commanddoesntexist\]"
  }
}

Describe "Negative Message Tests" {
  it "should not respond to '! help some random text which should error'" {
    $userInfo = Get-UserInformation

    # Post a Message
    $body = @{
      'channel_id' = $userInfo.channelid
      'message' = "! help some random text which should error"
    }
    $originalMessage = Invoke-MattermostAPI -Uri 'posts' -Method POST -Body $body

    # Give the bot time to respond
    Start-Sleep 3
    $updatedMessage = Invoke-MattermostAPI -Uri "posts/$($originalMessage.id)" -Method GET
    $updatedMessage.metadata.reactions.Count | Should -BeGreaterThan 0


    # The Bot should have a reaction on the message
    $updatedMessage.metadata.reactions[0].emoji_name | Should -Be 'exclamation'
  }
}
