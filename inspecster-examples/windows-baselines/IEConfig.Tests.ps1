# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/ie_config.rb

$random = 1536870911

control 'windows-ie-101' `
  -impact 1.0 `
  -title 'IE 64-bit tab' {
  describe "registry_key('HKLM\Software\Policies\Microsoft\Internet Explorer\Main')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-ie-102' `
  -impact 1.0 `
  -title 'Run antimalware programs against ActiveX controls' {
  describe "registry_key('HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
