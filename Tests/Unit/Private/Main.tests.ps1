#region Header
. $PSScriptRoot\..\..\helper.ps1
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\', '\src\' `
    -replace '\.tests', '' `
    -replace '\\unit\\', '\' `
    -replace 'ps1', 'psm1'
Import-Module $sut
#endregion
#region Setup Tests
$StigGroups = '<?xml version="1.0" encoding="utf-8"?>
<Group id="V-1000">
<title>Rule Title</title>
    <Rule id="SV-1000r2_rule" severity="high" weight="10.0">
    <check>
    <check-content>{0}</check-content>
    </check>
    </Rule>
</Group>'
#endregion
#region Main Tests

Describe "Get-StigRules" {

    <# 
        Set all of the test function to false to be inherited into each context and then set 
        the required test function to true in each context.
    #>
    It "Verifies the function 'Get-StigRules' exists" {
        Get-Command -Name Get-StigRules | Should Not BeNullOrEmpty
    }
}
#endregion

