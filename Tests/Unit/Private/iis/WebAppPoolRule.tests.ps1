#region Header
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\', '\src\' `
    -replace '\.tests', '' `
    -replace '\\unit\\', '\' `
    -replace 'ps1', 'psm1'
# load the helper script and system under test
. $PSScriptRoot\..\..\..\helper.ps1
Import-Module $sut
#endregion header

#region Test setup
$checkContent = 'Open the Internet Information Services (IIS) Manager.

Click the Application Pools.

Perform for each Application Pool.

Highlight an Application Pool to review and click "Advanced Settings" in the "Actions" pane.

Scroll down to the "Process Model" section and verify the value for "Ping Enabled" is set to "True".

If the value for "Ping Enabled" is not set to "True", this is a finding.'

#endregion Test Setup

#region Function Tests

Describe "ConvertTo-WebAppPoolRule" {
    $stigRule = Get-TestStigRule -CheckContent $checkContent -ReturnGroupOnly
    $rule = ConvertTo-WebAppPoolRule -StigRule $stigRule

    It "Should return an WebAppPoolRule object" {
        $rule.GetType() | Should Be 'WebAppPoolRule'
    }
}
#endregion Function Tests
