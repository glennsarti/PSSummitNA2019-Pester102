# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/privacy.rb

$random = 1536870911

control 'microsoft-online-accounts' `
  -impact 1.0 `
  -title 'Microsoft Online Accounts' `
  -desc 'Disabling Microsoft account logon sign-in option, eg. logging in without having to use local credentials and using microsoft online accounts' `
  -ref 'Block Microsoft Accounts', 'https://technet.microsoft.com/en-us/library/jj966262(v=ws.11).aspx' {
  describe "registry_key('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'disable-windows-store' `
  -impact 1.0 `
  -title 'Disable Windows Store' `
  -desc 'Ensure Turn off Automatic Download and Install ofupdates is set to Disabled' `
  -tag 'cis', '18.9.61.1' `
  -refs 'CIS Microsoft Windows Server 2012 R2 Benchmark', 'https://benchmarks.cisecurity.org/tools2/windows/CIS_Microsoft_Windows_Server_2012_R2_Benchmark_v2.2.1.pdf' {
  describe "registry_key('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'disable-index-encrypted-files' `
  -impact 1.0 `
  -title 'Disable indexing encrypted files' `
  -desc 'Ensure Allow indexing of encrypted files is set to Disabled' `
  -tag 'cis', '18.9.54.2' `
  -refs 'CIS Microsoft Windows Server 2012 R2 Benchmark', 'https://benchmarks.cisecurity.org/tools2/windows/CIS_Microsoft_Windows_Server_2012_R2_Benchmark_v2.2.1.pdf' {
  describe "registry_key('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
