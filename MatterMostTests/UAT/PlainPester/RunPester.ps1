try {
  & .\Pre-Pester.ps1

  $result = Invoke-Pester -Script $PSScriptRoot -PassThru # Add other options e.g. Output file, Passthru
}
finally {
  & .\Post-Pester.ps1 -Verbose:$true
}

# Return the number of failed tests. Exit Code 0 = Success
$host.setshouldexit($result.failedcount)
