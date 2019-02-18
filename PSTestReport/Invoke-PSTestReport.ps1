Param(
  [int]     $BuildNumber = 0,
  [string]  $GitRepo = "Repo Name",
  [string]  $GitRepoURL = "#",
  [string]  $CiURL = "#",
  [boolean] $ShowHitCommands = $false,
  [double]  $Compliance = 0.8,
  [string]  $ScriptAnalyzerFile = ".\artifacts\ScriptAnalyzerResults.json",
  [string]  $PesterFile = ".\artifacts\PesterResults.json",
  [string]  $OutputDir = ".\artifacts",
  [switch]  $FailOnSkippedOrPending
)

# HTML Colors
$Colors = @{
    GREEN = '#5cb85c'
    YELLOW = '#FFCE56'
    RED = '#FF6384'
}

# Load HTML Template
$templateFile = "$PSScriptRoot\lib\TestReport.htm"

# Load Pester JSON Files: Required
if (!(Test-Path $PesterFile))
{
    throw "$PesterFile is missing."
}
$Pester = Get-Content $PesterFile | ConvertFrom-Json

# Load ScriptAnalyzer JSON Files: Optional
$ScriptAnalyzer = $null;
if ((Test-Path $ScriptAnalyzerFile))
{
    $ScriptAnalyzer = Get-Content $ScriptAnalyzerFile | ConvertFrom-Json
}

# Copy Dependencies manually for now
Copy-Item -Recurse -Path "$PSScriptRoot\lib" -Destination (Join-Path $OutputDir "lib") -Force

# From Pester Source
function Get-HumanTime($Seconds)
{
    if($Seconds -gt 0.99) {
        $time = [math]::Round($Seconds, 2)
        $unit = 's'
    }
    else {
        $time = [math]::Floor($Seconds * 1000)
        $unit = 'ms'
    }
    return "$time$unit"
}

# Parse Git Commit
function Get-GitCommitHash($Length)
{
    $sha = $null

    try {
        $sha = (. git rev-parse HEAD).Substring(0, $length)
    }
    catch [System.Exception] {
        Write-Verbose "Git Hash could not be retrieved."
    }

    return $sha
}

function Get-TextImpact($Impact) {
    if ($Impact -eq $null) { Return 'none' }
    # From https://www.inspec.io/docs/reference/dsl_inspec/
    if ($Impact -is [System.String]) { return $Impact }
    if (($Impact -ge 0.0) -and ($Impact -lt 0.01)) { Return 'none' }
    if (($Impact -ge 0.01) -and ($Impact -lt 0.4)) { Return 'low' }
    if (($Impact -ge 0.4) -and ($Impact -lt 0.7)) { Return 'medium' }
    if (($Impact -ge 0.7) -and ($Impact -lt 0.9)) { Return 'high' }
    if (($Impact -ge 0.9) -and ($Impact -le 1.10)) { Return 'critical' }
}

function Get-WeightedScore($Impact) {
    switch ((Get-TextImpact -Impact $Impact)) {
        'none' { return 1 }
        'low' { return 2 }
        'medium' { return 3 }
        'high' { return 4 }
        'critical' { return 5 }
    }
}

function Get-LinkifiedText($value) {
    if ($value -like 'http*') { $value = "<a href='$value'>$value</a>" }
    Write-Output $value
}


# Create Test HTML Table
#$TestResults = $Pester.TestResult | Select-Object Result, Name, Describe, Context, FailureMessage, Time

# TODO Calculate Weighted test score
$WeightedTestTotalScore = 0
$WeightedTestPassedScore = 0
$FailedByImpact = @{
    'none' = 0
    'low' = 0
    'medium' = 0
    'high' = 0
    'critical' = 0
}

foreach($test in $Pester.TestResult)
{
    $metadata = $Test.Metadata
    $impactText = Get-TextImpact -Impact $Metadata.Impact

    $WeightedTestTotalScore += Get-WeightedScore -Impact $Metadata['Impact']
    switch ($test.Result) {
        "Passed" { $WeightedTestPassedScore += Get-WeightedScore -Impact $Metadata['Impact'] }
        "Skipped" { }
        "Pending" { }
        Default {
            # Assume a failed test here
            $desc = ([String]$metadata.Description).Trim()
            if ([String]::IsNullOrEmpty($desc)) { $desc = ([String]$metadata.Title).Trim() }
            if (![string]::IsNullOrEmpty($desc)) { $desc += "<br/>" }
            if ($metadata.Tags -eq $null) { $tags = @() } else { $tags = $metadata.Tags}
            if ($metadata.References -eq $null) { $refs = @() } else {
                $refs = @()
                $metadata.References | ForEach-Object {
                    $refs += Get-LinkifiedText -Value $_
                }
            }

            switch ($impactText) {
                'none'     { $status = "<span class='label label-default'><i class='fa fa-angle-double-down' aria-hidden='true' title='No impact'></i></span>" }
                'low'      { $status = "<span class='label label-info'><i class='fa fa-angle-down' aria-hidden='true' title='Low impact'></i></span>" }
                'medium'   { $status = "<span class='label label-warning'><i class='fa fa-grip-lines' aria-hidden='true' title='Medium impact'></i></span>" }
                'high'     { $status = "<span class='label label-warning'><i class='fa fa-angle-up' aria-hidden='true' title='High impact'></i></span>" }
                'critical' { $status = "<span class='label label-danger'><i class='fa fa-angle-double-up' aria-hidden='true' title='Critical impact'></i></span>" }
            }

            $FailedByImpact[$impactText] += 1
            $TestResultsTable += "
            <tr>
                <td nowrap>$status $($test.Describe)</td>
                <td>$($test.Name)</td>
                <td>$($tags -join ', ')</td>
                <td>$($desc)<br/>$($refs -join '<br/>')</td>
                <td>$($test.FailureMessage)</td>
            </tr>
        "
        }
    }
}

# Create Script Analyzer Table
foreach ($issue in $ScriptAnalyzer)
{
    if($issue.Severity -eq "1")
    {
        $status = "<span class='label label-warning'>Warning</span>"
    }
    else
    {
        $status = "<span class='label label-danger'>Error</span>"
    }

    $ScriptAnalysisTable += "
    <tr>
        <td>$status</td>
        <td>$($issue.RuleName)</td>
        <td>$($issue.ScriptName)</td>
        <td>$($issue.Line)</td>
        <td>$($issue.Column)</td>
        <td>$($issue.Message)</td>
    </tr>
    "
}

#Keep track of single file coverage so we only iterate once
$FileCoverage = @{}

foreach($file in $Pester.CodeCoverage.AnalyzedFiles)
{
    $FileCoverage[$file] = @{
        Hit = 0
        Missed = 0
    }
}

# Create Script for Coverage Table (missed)
Add-Type -AssemblyName System.Web
foreach($missed in $Pester.CodeCoverage.MissedCommands)
{
    $command = [System.Web.HttpUtility]::HtmlEncode($missed.Command)

    $CoverageTable += "
        <tr>
            <td><span class='label label-warning'>Missed</span></td>
            <td>$($missed.File)</td>
            <td>$($missed.Line)</td>
            <td>$($missed.Function)</td>
            <td><pre style='border:1px solid $($Colors.YELLOW); background-color: transparent;'>$($command)</pre></td>
        </tr>
    "

    $FileCoverage[$missed.File].Missed++
}

# Create Script for Coverage Table (hit)
foreach($hit in $Pester.CodeCoverage.HitCommands)
{
    if($ShowHitCommands)
    {
        $command = [System.Web.HttpUtility]::HtmlEncode($hit.Command)

        $CoverageTable += "
            <tr>
                <td><span class='label label-success'>Hit</span></td>
                <td>$($hit.File)</td>
                <td>$($hit.Line)</td>
                <td>$($hit.Function)</td>
                <td><pre style='border:1px solid $($Colors.GREEN); background-color: transparent;'>$command</pre></td>
            </tr>
        "
    }

   $FileCoverage[$hit.File].Hit++
}

# Create File Tested Table
# TODO: Add coverage % calcs for each file?
foreach($file in $FileCoverage.GetEnumerator())
{
    $total = ($file.Value.Hit + $file.Value.Missed)
    $coverage = [Math]::Round(($file.Value.Hit / $total) * 100, 2)

    if($coverage -lt 10)
    {
       $color = "progress-bar-danger"
    }
    elseif($coverage -lt 50)
    {
        $color = "progress-bar-warning"
    }
    else
    {
        $color = "progress-bar-success"
    }

    $FilesTestedTable += "
        <tr>
        <td>
            <span>$($file.Name)</span>
            <div class='progress' style='margin-bottom:0;'>
                <div class='progress-bar $color' role='progressbar' aria-valuenow='$coverage' aria-valuemin='0' aria-valuemax='100' style='width: $coverage%; min-width: 2em;'>$coverage %</div>
            </div>
        </td>
        </tr>
    "
}

if ($Pester.CodeCoverage.NumberOfCommandsAnalyzed -gt 0) {
    $OverallCoverage = ($Pester.CodeCoverage.NumberOfCommandsExecuted/$Pester.CodeCoverage.NumberOfCommandsAnalyzed)
} else {
    $OverallCoverage = 0
}


# Determine Pester overall status
if($Pester.FailedCount -eq 0)
{
    # If the switch $FailOnSkippedOrPending is set, any skipped or pending tests will fail the build.
    if ($FailOnSkippedOrPending -and ($Pester.PendingCount -ne 0) -and ($Pester.SkippedCount -ne 0) )
    {
        $PesterPassed = $false
    }
    else
    {
        $PesterPassed = $true
    }
}
else
{
    $PesterPassed = $false
}

# Replace Everything in html template and output report
$Replace = @{
    # Custom
    REPO = $GitRepo
    REPO_URL = $GitRepoURL
    CI_BUILD_URL = $CiURL
    NUMBER_OF_PS1_FILES = (Get-ChildItem -Recurse -Include *ps1 | Measure-Object).Count
    BUILD_NUMBER = $BuildNumber
    BUILD_DATE = Get-Date -Format u
    COMMIT_HASH = Get-GitCommitHash -Length 10

    # Generated
    BUILD_RESULT = if($OverallCoverage -ge $Compliance -and $PesterPassed) {"PASSED"} else {"FAILED"}
    BUILD_RESULT_COLOR = if($OverallCoverage -ge $Compliance -and$PesterPassed) {"panel-success"} else {"panel-danger"}
    BUILD_RESULT_ICON = if($OverallCoverage -ge $Compliance -and $PesterPassed) {"fa-check"} else {"fa-times"}

    TEST_TABLE = $TestResultsTable
    FILES_TESTED_TABLE = $FilesTestedTable
    SCRIPT_ANALYSIS_TABLE = $ScriptAnalysisTable
    TEST_OVERALL = [Math]::Round(($WeightedTestPassedScore/$WeightedTestTotalScore) * 100, 0)
    TEST_OVERALL_COLOR = if($Pester.FailedCount -eq 0) {$Colors.GREEN} else {$Colors.RED}
    COVERAGE_TABLE = $CoverageTable
    COVERAGE_OVERALL = [Math]::Round($OverallCoverage * 100, 0)
    COVERAGE_OVERALL_COLOR = if($OverallCoverage -lt 0.1) {$Colors.RED} elseif($OverallCoverage -lt 0.5) {$Colors.YELLOW} else {$Colors.GREEN}

    # Pester
    PASSED_COUNT = $Pester.PassedCount
    CRITICAL_CONTROL_FAILURE_COUNT = $FailedByImpact['critical']
    HIGH_CONTROL_FAILURE_COUNT = $FailedByImpact['high']
    MEDIUM_CONTROL_FAILURE_COUNT = $FailedByImpact['medium']
    LOW_CONTROL_FAILURE_COUNT = $FailedByImpact['low']
    NONE_CONTROL_FAILURE_COUNT = $FailedByImpact['none']
    SKIPPED_COUNT = $Pester.SkippedCount
    PENDING_COUNT = $Pester.PendingCount
    FAILED_COUNT = $Pester.FailedCount
    TOTAL_COUNT = $Pester.TotalCount

    NUMBER_OF_COMMANDS_ANALYZED = $Pester.CodeCoverage.NumberOfCommandsAnalyzed
    NUMBER_OF_FILES_ANALYZED = $Pester.CodeCoverage.NumberOfFilesAnalyzed
    NUMBER_OF_COMMANDS_EXECUTED = $Pester.CodeCoverage.NumberOfCommandsExecuted
    NUMBER_OF_COMMANDS_MISSED = $Pester.CodeCoverage.NumberOfCommandsMissed

    # Script Analyzer
    SA_ERROR_COUNT = ($ScriptAnalyzer | where-object {$_.Severity -eq "2"} | Measure-Object).Count
    SA_WARNING_COUNT = ($ScriptAnalyzer | where-object {$_.Severity -eq "1"} | Measure-Object).Count
}

$template = (Get-Content $templateFile)
foreach ($var in $Replace.GetEnumerator())
{
    # Write-Host "Replacing: $($var.key)"
    $template = $template | ForEach-Object { $_.replace( "{$($var.key)}", $var.value ) }
}

$template | Set-Content (Join-Path $OutputDir "TestReport.htm")
