#region Header
. $PSScriptRoot\..\..\..\helper.ps1
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\','\src\' `
                                             -replace '\.tests','' `
                                             -replace '\\unit\\','\' `
                                             -replace 'ps1', 'psm1'
Import-Module $sut -Force
#endregion
#region Test Setup
$checkContent = 'This is NA prior to v1709 of Windows 10.

Run "Windows PowerShell" with elevated privileges (run as administrator).

Enter "Get-ProcessMitigation -System".

If the status of "Heap: TerminateOnError" is "OFF", this is a finding.

Values that would not be a finding include:
ON
NOTSET'
#endregion
#region Tests
Describe "ConvertTo-ProcessMitigationRule" {

    $stigRule = Get-TestStigRule -CheckContent $checkContent -ReturnGroupOnly
    $rule = ConvertTo-ProcessMitigationRule -StigRule $stigRule

    It "Should return a ProcessMitigationRule object" {
        $rule.GetType() | Should Be 'ProcessMitigationRule'
    }
}
#endregion
