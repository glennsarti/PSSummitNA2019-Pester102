# Mattermost OAT Tests

### Plain Pester tests

``` powershell
Invoke-Pester -Script .\PlainPester
```

### OVF based Tests

Note - Need version 1.2.0 of OperationValidation Module

``` powershell
Get-OperationValidation -Path OVF

Invoke-OperationValidation -Path OVF

Invoke-OperationValidation -Path OVF -Overrides @{MatterMostRoot = 'http://localhost:8065'}
```

### InSpec

``` powershell
bundle install [other cmd line arguments here]

bundle exec inspec check .
```

### Inspectser

``` powershell
pwsh -Command "Import-Module ..\..\inspecster\Pester.psd1; Invoke-Pester Inspecster"
```
