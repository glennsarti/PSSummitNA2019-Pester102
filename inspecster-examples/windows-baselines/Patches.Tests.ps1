# Inspired from https://github.com/dev-sec/windows-patch-baseline/blob/master/controls/patches.rb

$random = 1536870911

control 'verify-kb' -impact 'none' -Title 'All updates should be installed' {
  describe 'win_update.all.length' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'important-count' -impact 1.0 -title 'No important updates should be available' {
  describe 'win_update.important.length' {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'important-patches' -impact 1.0 -title 'All important updates are installed' {
  describe update {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'optional-count' -impact 0.3 -title 'No optional updates should be available' {
  describe win_update.optional.length {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}

control 'optional-patches' -impact 0.3 -title 'All optional updates are installed' {
  describe update {
    it 'randomly fails' { Get-Random | Should -BeGreaterThan $random }
  }
}
