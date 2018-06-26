#region Header
. $PSScriptRoot\..\..\..\helper.ps1
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\','\src\' `
                                             -replace '\.tests','' `
                                             -replace '\\unit\\','\' `
                                             -replace 'ps1', 'psm1'
Import-Module $sut -Force
#endregion Header
#region Test Setup
#endregion Test Setup
#region Tests
Describe 'Get-AvailableId' {
    # Since this function uses a global variable, we need to make sure we don't step on anything. 
    $resetglobalSettings = $false
    if ( $Global:StigSettings )
    {
        [System.Collections.ArrayList] $globalSettings = $Global:StigSettings
        $resetglobalSettings = $true
    }

    try 
    {
        It 'Should ad the nexy available letter to an Id' {
            $Global:StigSettings = @(@{Id = 'V-1000'})
            Get-AvailableId -Id 'V-1000' | Should Be 'V-1000.a'
        }
    }
    finally
    {
        if ( $resetglobalSettings )
        {
            $Global:StigSettings = $globalSettings
        }
    }
}
#endregion
