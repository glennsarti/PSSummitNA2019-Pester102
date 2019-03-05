$MatterMostRoot = "http://localhost:8065"
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


control 'mattermost-basic-1' `
  -impact 'critical' `
  -title 'Mattermost Server: Basic Connectivity' `
  -desc 'Basic connectivity tests to test whether Mattermost is even running' `
  -tags 'mattermost', 'basic' {

  describe "Response from ${MatterMostRoot}" {
    it "should return statuscode 200" {
      $Result = Invoke-WebRequest -Uri $MatterMostRoot -UseBasicParsing

      $Result.StatusCode | Should -Be 200 -Because 'This indicates MatterMost is available'
    }

    it "should have a title of MatterMost" {
      $Result = Invoke-WebRequest -Uri $MatterMostRoot -UseBasicParsing

      $Result.Content | Should -BeLike "*<title>Mattermost</title>*" -Because 'Even if a HTTP port is open, it may not actually be a Mattermost Server'
    }
  }
}

control 'mattermost-basic-2' `
  -impact 'high' `
  -title 'Mattermost Server: Status Endpoint tests' `
  -tags 'status', 'health' `
  -refs 'https://api.mattermost.com/#tag/system%2Fpaths%2F~1system~1ping%2Fget', "${StatusURI}" `
  -desc 'Ensuring that the Status API is reporting an Ok status' {

  describe "Status endpoint at ${StatusURI}" {
    it "should return statuscode 200" {
      $Result = Invoke-WebRequest -Uri $StatusURI -UseBasicParsing

      $Result.StatusCode | Should -Be 200 -Because 'A Mattermost server should respond on the status API'
    }

    it "should have status of OK" {
      $Result = Invoke-WebRequest -Uri $StatusURI -UseBasicParsing

      ($Result.Content | ConvertFrom-JSON).status | Should -Be "OK" -Because 'The Mattermost server should not be a degredated state'
    }
  }
}

control 'mattermost-basic-3' `
  -impact 'medium' `
  -title 'Mattermost Server: Server Configuration tests' `
  -tags 'api', 'configuration', 'security' `
  -refs 'https://api.mattermost.com/#tag/APIv3-Deprecation', "https://api.mattermost.com/#tag/system%2Fpaths%2F~1config~1client%2Fget", "${MatterMostRoot}" `
  -desc 'Ensuring that configuration of the server is in the expected state' {

  describe "Server configuration" {
    it "should return statuscode 404 for V3 API" {
      $Result = Invoke-TrapWebErrors { Invoke-WebRequest -Uri "${MatterMostRoot}/api/v3" -UseBasicParsing }

      $Result.StatusCode | Should -Be 404 -Because 'The V3 API has been deprecated and should not be available'
    }

    it "should report MatterMost Server version 5.8.0" {
      $Result = Invoke-MattermostAPI -Uri "config/client?format=old" -Method Get

      $Result.Version | Should -Be "5.8.0"
    }
  }
}

control 'mattermost-auth-1' `
  -impact 'medium' `
  -title 'Mattermost Server: User Statistics Endpoint tests' `
  -desc 'Ensuring that the User Stats. endpoint is reporting the correct information' {

  Describe "Users API endpoint" {
    it "should have more than one user" {
      $Result = Invoke-MattermostAPI -Uri "users/stats" -Method Get

      $Result.total_users_count | Should -BeGreaterThan 1 -Because 'We setup many users in the Mattermost server.  Having only one indicates an error'
    }
  }
}
