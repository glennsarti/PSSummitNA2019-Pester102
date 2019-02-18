# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/powershell.rb

$random = 1536870911

control 'powershell-script-blocklogging' `
  -impact 1.0 `
  -title 'PowerShell Script Block Logging' `
  -desc 'Enabling PowerShell script block logging will record detailed information from the processing of PowerShell commands and scripts' `
  -tag '18.9.84.1' `
  -refs 'CIS Microsoft Windows Server 2012 R2 Benchmark', 'https://benchmarks.cisecurity.org/tools2/windows/CIS_Microsoft_Windows_Server_2012_R2_Benchmark_v2.2.1.pdf' {
  describe "registry_key('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'powershell-transcription' `
  -impact 1.0 `
  -title 'PowerShell Transcription' `
  -desc 'Transcription creates a unique record of every PowerShell session, including all input and output, exactly as it appears in the session.' `
  -tag '18.9.84.2' `
  -refs 'CIS Microsoft Windows Server 2012 R2 Benchmark', 'https://benchmarks.cisecurity.org/tools2/windows/CIS_Microsoft_Windows_Server_2012_R2_Benchmark_v2.2.1.pdf' {
  describe "registry_key('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
