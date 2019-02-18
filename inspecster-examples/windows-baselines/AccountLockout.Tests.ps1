# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/account_lockout.rb

$random = 1536870911

control 'cis-account-lockout-duration-1.2.1' `
  -impact 0.7 `
  -title '1.2.1 Set Account lockout duration to 15 or more minutes' `
  -desc 'Set Account lockout duration to 15 or more minutes' {
  describe "security_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-account-lockout-threshold-1.2.2'`
  -impact 0.7 `
  -title '1.2.2 Set Account lockout threshold to 10 or fewer invalid logon attempts but not 0' `
  -desc 'Set Account lockout threshold to 10 or fewer invalid logon attempts but not 0' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-reset-account-lockout-1.2.3' `
  -impact 0.7 `
  -title '1.2.3 Set Reset account lockout counter after to 15 or more minutes' `
  -desc 'Set Reset account lockout counter after to 15 or more minutes' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-100' `
  -impact 1.0 `
  -title 'Windows Remote Desktop Configured to Only Allow System Administrators Access' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-101' `
  -impact 1.0 `
  -title 'Windows Default Guest Account is Disabled' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-102' `
  -impact 1.0 `
  -title 'Windows Password Complexity is Enabled' `
  -tags 'windows_2012r2:1.1.5', 'windows_2016:1.1.5' `
  -refs 'Password must meet complexity requirements', `
        'https://technet.microsoft.com/en-us/library/hh994562(v=ws.11).aspx', `
        'CIS Microsoft Windows Server 2012 R2 Benchmark', `
        'CIS Microsoft Windows Server 2016 RTM (Release 1607) Benchmark' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-103' `
  -impact 1.0 `
  -title 'Minimum Windows Password Length Configured to be at Least 8 Characters' `
  -desc 'Minimum password length' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-104' `
  -impact 1.0 `
  -title 'Set Windows Account lockout threshold' `
  -desc 'Account lockout threshold, see https://technet.microsoft.com/en-us/library/hh994574.aspx' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-105' `
  -impact 1.0 `
  -title 'Windows Account Lockout Counter Configured to Wait at Least 30 Minutes Before Reset' `
  -desc 'Reset lockout counter after, see https://technet.microsoft.com/en-us/library/hh994568.aspx' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-account-106' `
  -impact 1.0 `
  -title 'Windows Account Lockout Duration Configured to at Least 30 Minutes' `
  -desc 'Account lockout duration, see https://technet.microsoft.com/en-us/library/hh994569.aspx' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
