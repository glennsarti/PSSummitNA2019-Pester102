function Control {
    <#
.SYNOPSIS
Provides logical grouping of It blocks within a single Describe block.

.DESCRIPTION
Provides logical grouping of It blocks within a single Describe block.
Any Mocks defined inside a Control are removed at the end of the Control scope,
as are any files or folders added to the TestDrive during the Control block's
execution. Any BeforeEach or AfterEach blocks defined inside a Control also only
apply to tests within that Control .

.PARAMETER Name
The name of the Control. This is a phrase describing a set of tests within a describe.

.PARAMETER Tag
Optional parameter containing an array of strings.  When calling Invoke-Pester,
it is possible to specify a -Tag parameter which will only execute Control blocks
containing the same Tag.

.PARAMETER Fixture
Script that is executed. This may include setup specific to the Control
and one or more It blocks that validate the expected outcomes.

.EXAMPLE
function Add-Numbers($a, $b) {
    return $a + $b
}

Control "Add-Numbers" {

    It "..." { ... }

    Context "when root does exist" {
        It "..." { ... }
        It "..." { ... }
        It "..." { ... }
    }
}

TODO - Add this to the docs

https://www.inspec.io/docs/reference/dsl_inspec/

Impact

impact is a string, or numeric that measures the importance of the compliance results. Valid strings for impact are none, low, medium, high, and critical. The values are based off CVSS 3.0. A numeric value must be between 0.0 and 1.0. The value ranges are:
0.0 to <0.01 these are controls with no impact, they only provide information
0.01 to <0.4 these are controls with low impact
0.4 to <0.7 these are controls with medium impact
0.7 to <0.9 these are controls with high impact
0.9 to 1.0 these are critical controls


.LINK
Describe
It
BeforeEach
AfterEach
about_Should
about_Mocking
about_TestDrive

#>
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Alias('Tags')]
        [string[]] $Tag = @(),

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            $ErrMsg = "Expected a number from 0.0 to 1.0, or a string of 'none', 'low', 'medium', 'high', or 'critical' but got '[$($_.GetType().ToString())] $_'"
            if ($_ -is [System.String]) {
                if (@('none', 'low', 'medium', 'high', 'critical') -notcontains $_.ToLower()) { Throw $ErrMsg }
            } else {
                $value = $null
                if ([Double]::TryParse($_.ToString(), [ref] $value)) {
                    if (($value -lt 0) -or ($value -gt 1.0)) { Throw $ErrMsg }
                } else {
                   Throw $ErrMsg
                }
            }
            $true
        })]
        $Impact,

        [Parameter(Mandatory = $false)]
        [string] $Title,

        [Alias('desc')]
        [Parameter(Mandatory = $false)]
        [string] $Description,

        [Alias('refs')]
        [Parameter(Mandatory = $false)]
        [string[]] $References,


        # [Parameter(Mandatory = $false)]
        # [hashtable] $Metadata = @{},

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [ScriptBlock] $Fixture = $(Throw "No test script block is provided. (Have you put the open curly brace on the next line?)")
    )

    if ($null -eq (& $SafeCommands['Get-Variable'] -Name Pester -ValueOnly -ErrorAction $script:IgnoreErrorPreference)) {
        # User has executed a test script directly instead of calling Invoke-Pester
        $sessionState = Set-SessionStateHint -PassThru -Hint "Caller - Captured in Control" -SessionState $PSCmdlet.SessionState
        $Pester = New-PesterState -Path (& $SafeCommands['Resolve-Path'] .) -TestNameFilter $null -TagFilter @() -SessionState SessionState
        $script:mockTable = @{}
    }

    $Metadata = @{}
    # Normalise the Impact Parameter
    If ($Impact -ne $null) {
        if ($Impact -is [System.String]) {
            $Metadata['Impact'] = $Impact.ToLower()
            $CommandUsed += " [" + $Metadata['Impact'] + "]"
        } else {
            $Metadata['Impact'] = [Double]::Parse($Impact.ToString())
        }
    }
    If ($Title -ne $null) { $Metadata['Title'] = $Title }
    If ($Description -ne $null) { $Metadata['Description'] = $Description }
    If ($References -ne $null) { $Metadata['References'] = $References }
    if ($Tag -ne $null) { $Metadata['Tags'] = $Tag}

    $describeSplat = @{}
    # Note - Can't use @PSBoundParameters here due to extra properties so build a hashtable with those parameters removed
    $PSBoundParameters.GetEnumerator() | Where-Object { @('Impact', 'Title', 'Metadata', 'Description', 'References') -notcontains $_.Key } | ForEach-Object { $describeSplat[$_.Key] = $_.Value }

    DescribeImpl @describeSplat -Metadata $Metadata -CommandUsed 'Control' -Pester $Pester -DescribeOutputBlock ${function:Write-Describe} -TestOutputBlock ${function:Write-PesterResult} -NoTestRegistry:('Windows' -ne (GetPesterOs))
}
