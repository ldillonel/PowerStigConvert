# Build the path to the system under test
[string] $sut = $MyInvocation.MyCommand.Path -replace '\\tests\\','\src\' `
                                             -replace '\.tests','' `
                                             -replace '\\unit\\','\'
# load the system under test
. $sut

# Import the base benchmark xml string data.
$BaseXccdfContent = Get-Content -Path "$PSScriptRoot\..\..\..\sampleXccdf.xml.txt" -Encoding UTF8

Describe "New-OrganizationalSettingsXmlFile" {

    Mock -CommandName Get-StigObjectsWithOrgSettings -MockWith {}
    # Needs to be expanded to use sample data.
    It "Should exist" {
        Get-Command New-OrganizationalSettingsXmlFile | Should Not BeNullOrEmpty
    }
}


Describe "Get-StigVersionNumber" {
    # Needs to be expanded to use sample data.
    It "Should exist" {
        Get-Command Get-StigVersionNumber | Should Not BeNullOrEmpty
    }
}

Describe "Get-StigObjectsWithOrgSettings" {

    # Needs to be expanded to use sample data. 
    It "Should exist" {
        Get-Command  Get-StigObjectsWithOrgSettings | Should Not BeNullOrEmpty
    }
}

Describe "Get-CompositeTargetFolder" {

    $titleList = @{
        "Windows Server 2012/2012 R2 Domain Controller Security Technical Implementation Guide" = 'WindowsServerDC'
        "Windows Server 2012/2012 R2 Member Server Security Technical Implementation Guide"     = 'WindowsServerMS'
    }

    $TestFile = "TestDrive:\TextData.xml"

    foreach ($title in $titleList.GetEnumerator())
    {
        It "Should return '$($title.value)' from '$($title.key)' " {
            $BaseXccdfContent -f $title.key,'','','' | Out-File $TestFile
            Get-CompositeTargetFolder -Path $TestFile | Should Be $title.Value
        }
    }
}

Describe "Get-OutputFileRoot" {

    # Needs to be expanded to use sample data. 
    It "Should exist" {
        Get-Command  Get-OutputFileRoot | Should Not BeNullOrEmpty
    }
}
