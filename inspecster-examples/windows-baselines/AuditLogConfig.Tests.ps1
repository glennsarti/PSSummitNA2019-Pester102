# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/audit_log_config.rb

$random = 1536870911

control 'windows-audit-100' `
  -impact 0.1 `
  -title 'Configure System Event Log (Application)' `
  -desc 'Only applies for Windows 2008 and newer' {
  describe "registry_key('HKLM\Software\Policies\Microsoft\Windows\EventLog\Application')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-101' `
  -impact 0.1 `
  -title 'Configure System Event Log (Security)' `
  -desc 'Only applies for Windows 2008 and newer' {
  describe "registry_key('HKLM\Software\Policies\Microsoft\Windows\EventLog\Security')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-102' `
  -impact 0.1 `
  -title 'Configure System Event Log (Setup)' `
  -desc 'Only applies for Windows 2008 and newer' {
  describe "registry_key('HKLM\Software\Policies\Microsoft\Windows\EventLog\Setup')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-103' `
  -impact 0.1 `
  -title 'Configure System Event Log (System)' `
  -desc 'Only applies for Windows 2008 and newer' {
  describe "registry_key('HKLM\Software\Policies\Microsoft\Windows\EventLog\System')" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-201' `
  -impact 1.0 `
  -title 'Kerberos Authentication Service Audit Log' `
  -desc 'policy_name: Audit Kerberos Authentication Service' `
  -refs 'policy_path: Computer Configuration\Windows Settings\Advanced Audit Policy Configuration\Audit Policies\Account Logon' {
  describe "audit_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-202' `
  -impact 1.0 `
  -title 'Kerberos Service Ticket Operations Audit Log' `
  -desc 'policy_name: Audit Kerberos Service Ticket Operations' `
  -refs 'policy_path: Computer Configuration\Windows Settings\Advanced Audit Policy Configuration\Audit Policies\Account Logon' {
  describe "audit_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-203' `
  -impact 1.0 `
  -title 'Account Logon Audit Log' `
  -desc 'policy_name: Audit Other Account Logon Events' `
  -refs 'policy_path: Computer Configuration\Windows Settings\Advanced Audit Policy Configuration\Audit Policies\Account Logon' {
  describe "audit_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-204' `
  -impact 1.0 `
  -title 'Audit Application Group Management' `
  -refs 'policy_path: Computer Configuration\Windows Settings\Advanced Audit Policy Configuration\Audit Policies\Account Management' {
  describe "audit_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-205' `
  -impact 1.0 `
  -title 'Audit Computer Account Management' `
  -refs 'policy_path: Computer Configuration\Windows Settings\Advanced Audit Policy Configuration\Audit Policies\Account Management',
        'CIS Microsoft Windows Server 2012 R2 Benchmark',
        'CIS Microsoft Windows Server 2016 RTM (Release 1607) Benchmark' `
  -tags 'windows_2012r2:17.2.2', 'windows_2016L:17.2.2' {
  describe "audit_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'windows-audit-206' `
  -impact 1.0 `
  -title 'Audit Distributed Group Management' `
  -refs 'policy_path: Computer Configuration\Windows Settings\Advanced Audit Policy Configuration\Audit Policies\Account Management' {
  describe "audit_policy" {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
