#region Header
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\','\src\' `
                                             -replace '\.tests','' `
                                             -replace '\\unit\\','\' `
                                             -replace 'ps1', 'psm1'
# load the helper script and system under test
. $PSScriptRoot\..\..\..\helper.ps1
Import-Module $sut
#endregion header

#region Test setup
$checkContent = 'Note: If the Windows DNS server is in the classified network, this check is Not Applicable.

Log on to the authoritative DNS server using the Domain Admin or Enterprise Admin account.

Press Windows Key + R, execute dnsmgmt.msc.

Right-click the DNS server, select “Properties”.

Select the "Root Hints" tab.

Verify the "Root Hints" is either empty or only has entries for internal zones under "Name servers:". All Internet root server entries must be removed.

If "Root Hints" is not empty and the entries on the "Root Hints" tab under "Name servers:" are external to the local network, this is a finding.'

#endregion Test Setup

#region Function Tests
Describe "ConvertTo-DnsServerRootHintRule" {
    $stigRule = Get-TestStigRule -CheckContent $checkContent -ReturnGroupOnly
    $rule = ConvertTo-DnsServerRootHintRule -StigRule $stigRule

    It "Should return an DnsServerRootHintRule object" {
        $rule.GetType() | Should Be 'DnsServerRootHintRule'
    }
}
#endregion Function Tests
