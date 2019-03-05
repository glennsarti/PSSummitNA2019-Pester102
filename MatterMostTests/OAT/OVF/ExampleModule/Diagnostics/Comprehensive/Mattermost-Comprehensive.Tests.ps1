param(
  $MatterMostRoot = "http://localhost:8065"
)

$StatusURI = "${MatterMostRoot}/api/v4/system/ping"

function Invoke-AuthenticateMatterMost() {
  $loginURI = $MatterMostRoot + '/api/v4/users/login'
  $r = Invoke-WebRequest -URI $loginURI -Method POST -Body (@{ "login_id" = 'poshbot@example.com'; "password" ='Password1' } | ConvertTo-JSON) -UseBasicParsing -ContentType 'application/json'
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

  $result = Invoke-RestMethod @iwrProps -Headers $headers

  $result
}

Function Invoke-TrapWebErrors([scriptblock]$sb) {
  # Unfortunately Invoke-WebRequest throws errors for 4xx/5xx errors, but we may want
  # the raw HTML response e.g. for testing specific error codes.  In this case, run
  # an arbitrary ScriptBlock and trap WebExceptions and return the response object
  $result = try {
    & $sb
  } catch [System.Net.WebException] {
    # Windows PowerShell raises a System.Net.WebException error
    $_.Exception.Response
  } catch {
    # PowerShell Core raises a stadard PowerShell error class with the exception within.
    if ($_.Exception.GetType().ToString() -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
      $_.Exception.Response
    } else {
      Throw $_
    }
  }

  $result
}

Describe "Mattermost Comprehensive Tests" {
  Context "Server configuration" {
    it "should return statuscode 404 for V3 API" {
      $Result = Invoke-TrapWebErrors { Invoke-WebRequest -Uri "${MatterMostRoot}/api/v3" -UseBasicParsing }

      $Result.StatusCode | Should -Be 404 -Because 'The V3 API has been deprecated and should not be available'
    }

    it "should report MatterMost Server version 5.8.0" {
      $Result = Invoke-MattermostAPI -Uri "config/client?format=old" -Method Get

      $Result.Version | Should -Be "5.8.0"
    }
  }

  Context "Status endpoint at ${StatusURI}" {
    it "should return statuscode 200" {
      $Result = Invoke-WebRequest -Uri $StatusURI -UseBasicParsing

      $Result.StatusCode | Should -Be 200 -Because 'A Mattermost server should respond on the status API'
    }

    it "should have status of OK" {
      $Result = Invoke-WebRequest -Uri $StatusURI -UseBasicParsing

      ($Result.Content | ConvertFrom-JSON).status | Should -Be "OK" -Because 'The Mattermost server should not be a degredated state'
    }
  }

  Context "Users API endpoint" {
    it "should have more than one user" {
      $Result = Invoke-MattermostAPI -Uri "users/stats" -Method Get

      $Result.total_users_count | Should -BeGreaterThan 1 -Because 'We setup many users in the Mattermost server.  Having only one indicates an error'
    }
  }
}
