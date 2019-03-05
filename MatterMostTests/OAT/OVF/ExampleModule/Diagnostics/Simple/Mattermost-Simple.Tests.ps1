param(
  $MatterMostRoot = "http://localhost:8065"
)

Describe "Mattermost Simple Tests" {
  Context "Response from $MatterMostRoot" {
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
