# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/user_rights.rb

$random = 1536870911

control 'cis-access-cred-manager-2.2.1' `
  -impact 0.7 `
  -title '2.2.1 Set Access Credential Manager as a trusted caller to No One' `
  -desc 'Set Access Credential Manager as a trusted caller to No One' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-network-access-2.2.2' `
  -impact 0.7 `
  -title '2.2.2 Set Access this computer from the network' `
  -desc 'Set Access this computer from the network' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-act-as-os-2.2.3' `
  -impact 0.7 `
  -title '2.2.3 Set Act as part of the operating system to No One' `
  -desc 'Set Act as part of the operating system to No One' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-add-workstations-2.2.4' `
  -impact 0.7 `
  -title '2.2.4 Set Add workstations to Domain to Administrators' `
  -desc 'Set Add workstations to Domain to Administrators' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-adjust-memory-quotas-2.2.5' `
  -impact 0.7 `
  -title '2.2.5 Set Adust memory quotas for a process to Administrators, LOCAL SERVICE, NETWORK SERVICE' `
  -desc 'Set Adust memory quotas for a process to Administrators, LOCAL SERVICE, NETWORK SERVICE' {
  describe 'security_policy' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
