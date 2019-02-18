# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/access_config.rb

$random = 1536870911

control 'windows-base-100' -impact 1.0 -title 'Verify the Windows folder permissions are properly set' {
  describe "file('c:/windows')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

## NTLM

control 'windows-base-101' `
  -impact 1.0 `
  -title 'Safe DLL Search Mode is Enabled' `
  -Description 'cannot be managed via group policy' `
  -References 'https://msdn.microsoft.com/en-us/library/ms682586(v=vs.85).aspx','https://technet.microsoft.com/en-us/library/dd277307.aspx' {
  describe "registry_key('HKLM\System\CurrentControlSet\Control\Session Manager')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

# MSS: (SafeDllSearchMode) Enable Safe DLL search mode (recomm}ed)
# Ensure voulmes are using the NTFS file systems
control 'windows-base-102' `
  -impact 1.0 `
  -title 'Anonymous Access to Windows Shares and Named Pipes is Disallowed' `
  -tags 'cis windows_2012r2:2.3.11.8', 'cis windows_2016:2.3.10.9' `
  -refs 'CIS Microsoft Windows Server 2012 R2 Benchmark','CIS Microsoft Windows Server 2016 RTM (Release 1607) Benchmark' {
  describe "registry_key('HKLM\System\CurrentControlSet\Services\LanManServer\Parameters')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-base-103' -impact 1.0 -title 'All Shares are Configured to Prevent Anonymous Access' {
  describe "registry_key('HKLM\System\CurrentControlSet\Services\LanManServer\Parameters')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-base-104' -impact 1.0 -title 'Force Encrypted Windows Network Passwords' {
  describe "registry_key('HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-base-105' -impact 1.0 -title 'SMB1 to Windows Shares is disabled' -desc 'All Windows Shares are Configured to disable the SMB1 protocol' {

  describe "registry_key('HKLM\System\CurrentControlSet\Services\LanManServer\Parameters')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

## LSA Authentication
# @link: https://msdn.microsoft.com/en-us/library/windows/desktop/aa378326(v=vs.85).aspx

control 'windows-base-201' -impact 1.0 -title 'Strong Windows NTLMv2 Authentication Enabled; Weak LM Disabled'-refs 'http://support.microsoft.com/en-us/kb/823659' {
  describe "registry_key('HKLM\System\CurrentControlSet\Control\Lsa')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-base-202' -impact 1.0 -title 'Enable Strong Encryption for Windows Network Sessions on Clients' {
  describe "registry_key('HKLM\System\CurrentControlSet\Control\Lsa\MSV1_0')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-base-203' -impact 1.0 -title 'Enable Strong Encryption for Windows Network Sessions on Servers' {
  describe "registry_key('HKLM\System\CurrentControlSet\Control\Lsa\MSV1_0')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
