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
$checkContent = 'Log on to the DNS server using the Domain Admin or Enterprise Admin account.

Press Windows Key + R, execute dnsmgmt.msc.

Right-click the DNS server, select “Properties”.

Click on the “Event Logging” tab. By default, all events are logged.

Verify "Errors and warnings" or "All events" is selected.

If any option other than "Errors and warnings" or "All events" is selected, this is a finding.'

#endregion Test Setup

#region Function Tests
Describe "Private DnsServerSetting Rule tests" {

    # Regular expression tests    
    Context "Dns Stig Rules regex tests" { 

        $text = 'the          forwarders     tab.'
        $result = $text -match $script:RegularExpression.textBetweenTheTab 
        It "Should match text inside of the words 'the' and 'tab'" {
            $result | Should be $true
        }
        It "Should return text between the words 'the' and 'tab'" {
            $($Matches.1).Trim() | Should Be 'forwarders'
        }

        [string]$text = ' âForwardersâ'
        $result = $text -match $script:RegularExpression.nonLetters
        It "Should match any non letter characters" {
            $result | Should Be $true
        }
        It "Should remove the non word characters" {
            $result = $text -replace $script:RegularExpression.nonLetters
            $result.Trim() | Should Be 'Forwarders'
        }
    }
}

Describe "ConvertTo-DnsServerSettingRule" {
    $stigRule = Get-TestStigRule -CheckContent $checkContent -ReturnGroupOnly
    $rule = ConvertTo-DnsServerSettingRule -StigRule $stigRule

    It "Should return an DnsServerSettingRule object" {
        $rule.GetType() | Should Be 'DnsServerSettingRule'
    }
}
#endregion Function Tests
