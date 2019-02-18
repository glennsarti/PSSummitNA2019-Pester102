# Cleanup
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath 'artifacts'
$outputFile = Join-Path -Path $outputDir -ChildPath 'PesterResults.json'

if (-not (Test-Path -Path $outputDir)) { New-Item -Path $outputDir -ItemType Directory | Out-Null }
if (Test-Path -Path $outputFile) { Remove-Item -Path $outputFile -Force -Confirm:$false | Out-Null }

# Run the Inspecster tests...
Import-Module ..\inspecster\Pester.psd1
Invoke-Pester ..\MatterMostTests\OAT\Inspecster -PassThru | ConvertTo-Json -Depth 5 | Set-Content $outputFile

# Create the report
& .\Invoke-PSTestReport.ps1 -BuildNumber 26 -GitRepo 'PSSummitNA2019' -GitRepoURL 'https://github.com/glennsarti/PSSummitNA2019-Pester102' -CiURL 'https://azdevops.something/build/26'
