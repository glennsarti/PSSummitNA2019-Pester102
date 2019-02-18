# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/rdp_config.rb

$random = 1536870911

control 'windows-rdp-100' `
  -impact 1.0 `
  -title 'Windows Remote Desktop Configured to Always Prompt for Password' {
  describe "registry_key('HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-rdp-101' `
  -impact 1.0 `
  -title 'Strong Encryption for Windows Remote Desktop Required' {
  describe "registry_key('HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
