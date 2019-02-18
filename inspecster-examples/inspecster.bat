@ECHO OFF

pwsh -Command "Import-Module ..\inspecster\Pester.psd1; (Invoke-Pester %*).TestResult | ConvertTo-JSON -Depth 1"
