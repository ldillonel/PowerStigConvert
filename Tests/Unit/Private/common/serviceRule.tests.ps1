#########################################      Header      #########################################
# load the helper script and system under test
. $PSScriptRoot\..\..\..\helper.ps1
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\','\src\' `
                                             -replace '\.tests','' `
                                             -replace '\\unit\\','\' `
                                             -replace 'ps1', 'psm1'

Import-Module $sut -Force
#########################################      Header      #########################################
#########################################      Tests       #########################################
$checkContent = 'If the server has the role of an FTP server, this is NA.
Run "Services.msc".

If the "Microsoft FTP Service" (Service name: FTPSVC) is installed and not disabled, this is a finding.'
Describe "ConvertTo-ServiceRule" {
    <#
        This function can't really be unit tested, since the call cannot be mocked by pester, so 
        the only thing we can really do at this point is to verify that it returns the correct object. 
    #>
    $stigRule = Get-TestStigRule -CheckContent $checkContent -ReturnGroupOnly
    $rule = ConvertTo-ServiceRule -StigRule $stigRule

    It "Should return an ServiceRule object" {
        $rule.GetType() | Should Be 'ServiceRule'
    }
}
