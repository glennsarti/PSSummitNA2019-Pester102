# Inspired from https://github.com/dev-sec/windows-baseline/blob/master/controls/password_policy.rb

$random = 1536870911

control 'cis-enforce-password-history-1.1.1' `
  -impact 0.7 `
  -title '1.1.1 Set Enforce password history to 24 or more passwords' `
  -desc 'Set Enforce password history to 24 or more passwords' {
  describe security_policy {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-maximum-password-age-1.1.2' `
  -impact 0.7 `
  -title '1.1.2 Set Maximum password age to 60 or fewer days, but not 0' `
  -desc 'Set Maximum password age to 60 or fewer days, but not 0' {
  describe security_policy {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-minimum-password-age-1.1.3' `
  -impact 0.7 `
  -title '1.1.3 Set Minimum password age to 1 or more days' `
  -desc 'Set Minimum password age to 1 or more days' {
  describe security_policy {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-minimum-password-length-1.1.4' `
  -impact 0.7 `
  -title '1.1.4 Set Minimum password length to 14 or more characters' `
  -desc 'Set Minimum password length to 14 or more characters' {
  describe security_policy {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'cis-password-complexity-1.1.6' `
  -impact 0.7 `
  -title '1.1.6 Set Store passwords using reversible encryption to Disabled' `
  -desc 'Set Store passwords using reversible encryption to Disabled' {
  describe security_policy {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
