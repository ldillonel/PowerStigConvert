#region Header
using module ..\src\public\common\enum.psm1
. $PSScriptRoot\..\src\public\common\data.ps1
#endregion Header
#region Support Functions
<#
    .SYNOPSIS
        Used to process the Check-Content test strings the same way that the SplitCheckContent
        static method does in the the STIG base class.

    .PARAMETER CheckContent
        Strings to process.
#>
function Split-TestStrings
{
    [OutputType([string[]])]
    param
    (
        [Parameter(mandatory = $true)]
        [string]
        $CheckContent
    )

    $CheckContent -split '\n' |
        Select-String -Pattern "\w" |
            ForEach-Object { $PSitem.ToString().Trim() }
}

<#
 .SYNOPSIS
    Validate Xml Schema

 .DESCRIPTION
    Validates an XML file against its inline provided schema reference

 .PARAMETER XmlPath
    Filename of the XML file to validate

 .PARAMETER XsdPath
    Filename of the XML schema file to validate the XmlPath file

 .EXAMPLE
    Test-Xml -XmlPath data.xml -XsdPath data.xsd

 .NOTES
    https://stackoverflow.com/questions/822907/how-do-i-use-powershell-to-validate-xml-files-against-an-xsd
#>
Function Test-Xml
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline, Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]
        $XmlPath,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]
        $XsdPath
    )

    [System.Collections.ArrayList] $Script:XmlValidationErrorLog = @()
    [scriptblock] $ValidationEventHandler = {
        $Script:XmlValidationErrorLog.Add("Line: $($_.Exception.LineNumber) Offset: $($_.Exception.LinePosition) - $($_.Message)")
    }

    $readerSettings = New-Object -TypeName System.Xml.XmlReaderSettings
    $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
    $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints -bor
                                      [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor
                                      [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings

    $readerSettings.add_ValidationEventHandler($ValidationEventHandler)
    try
    {
        $reader = [System.Xml.XmlReader]::Create( $XmlPath, $readerSettings )
        while ($reader.Read()) { }
    }
    finally
    {
        # Handler to ensure we always close the reader since it locks files
        $reader.Close()
    }

    if ( $Script:XmlValidationErrorLog )
    {
        Write-Warning "Xml file ""$XmlPath"" is NOT valid according to schema ""$XsdPath"""

        foreach ( $entry in $Script:XmlValidationErrorLog )
        {
            Write-Warning -Message $entry
        }
        Throw "$($Script:XmlValidationErrorLog.Count) errors found"
    }
    else
    {
        Write-Verbose "Xml file ""$XmlPath"" is valid according to schema ""$XsdPath"""
    }
}

<#
    .SYNOPSIS
        Creates a sample xml docuement that injects class specifc data

    .PARAMETER TestFile
        The test rule to merge into the data
#>
function Get-TestStigRule
{
    [CmdletBinding(DefaultParameterSetName = 'UseExisting')]
    param
    (
        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $XccdfTitle = '(Technology) Security Technical Implementation Guide',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $XccdfRelease = 'Release: 1 Benchmark Date: 1 Jan 1970',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $XccdfVersion = '2',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $XccdfId = 'Technology_Target',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $CheckContent = 'This is a string of text that tells an admin what item to check to verify compliance.',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $GroupId = 'V-1000',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $GroupTitle = 'Sample Title',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $GroupRuleTitle = 'A more descriptive title.',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $GroupRuleDescription = 'A description of what this vulnerability addresses and how it mitigates the threat.',

        [Parameter(Parametersetname = 'UseExisting')]
        [string]
        $FixText = 'This is a string of text that tells an admin how to fix an item if it is not currently configured properly and ignored by the parser',

        [Parameter(Parametersetname = 'UseExisting')]
        [Parameter(Parametersetname = 'FileProvided')]
        [switch]
        $ReturnGroupOnly,

        [Parameter(Mandatory = $true, Parametersetname = 'FileProvided')]
        [string]
        $FilePathToGroupElementText
    )

    # If a file path is provided, override the default sample group element text.
    if ( $FilePathToGroupElementText )
    {
        try
        {
            $groupElement = Get-Content -Path $FilePathToGroupElementText -Raw
        }
        catch
        {
            throw "$FilePathToGroupElementText was not found"
        }
    }
    else
    {
        # Get the samplegroup element text and merge in the parameter strings
        $groupElement = Get-Content -Path "$PSScriptRoot\data\sampleGroup.xml.txt" -Encoding UTF8 -Raw
        $groupElement = $groupElement -f $GroupId, $GroupTitle, $RuleTitle, $RuleDescription, $FixText, $CheckContent
    }

    # Get and merge the group element data into the xccdf xml document and create an xml object to return
    $xmlDocument = Get-Content -Path "$PSScriptRoot\data\sampleXccdf.xml.txt" -Encoding UTF8 -Raw
    [xml] $xmlDocument = $xmlDocument -f $XccdfTitle, $XccdfRelease, $XccdfVersion, $groupElement, $XccdfId

    # Some tests only need the group to test functionality.
    if ($ReturnGroupOnly)
    {
        return $xmlDocument.Benchmark.group
    }

    return $xmlDocument
}

<#
    .SYNOPSIS
        Used to retrieve an array of Stig class base methods and optionally add child class methods
        for purpose of testing methods

    .PARAMETER ChildClassMethodNames
        An array of child class method to add to the class base methods

    .EXAMPLE
        $RegistryRuleClassMethods = Get-StigBaseMethods -ChildClassMethodsNames @('SetKey','SetName')
#>
Function Get-StigBaseMethods
{
    [OutputType([System.Collections.ArrayList])]
    param
    (
        [Parameter()]
        [system.array]
        $ChildClassMethodNames,

        [Parameter()]
        [switch]
        $Static
    )

    if ( $Static )
    {
        $stigClassMethodNames = @('Equals', 'new', 'ReferenceEquals', 'SplitCheckContent',
            'GetRuleTypeMatchList', 'GetFixText')
    }
    else
    {
        $objectClassMethodNames = @('Equals', 'GetHashCode', 'GetType', 'ToString')
        $stigClassMethodNames = @('Clone', 'IsDuplicateRule', 'SetDuplicateTitle', , 'SetStatus',
            'SetIsNullOrEmpty', 'SetOrganizationValueRequired', 'GetOrganizationValueTestString',
            'ConvertToHashTable', 'SetStigRuleResource', 'IsHardCoded', 'GetHardCodedString',
            'IsHardCodedOrganizationValueTestString', 'GetHardCodedOrganizationValueTestString',
            'IsExistingRule')

        $stigClassMethodNames += $ObjectClassMethodNames
    }

    if ( $ChildClassMethodNames )
    {
        $stigClassMethodNames += $ChildClassMethodNames
    }

    return ( $stigClassMethodNames | Select-Object -Unique )
}

function Format-RuleText
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]
        $RuleText
    )

    $return = ($RuleText -split '\n' |
                Select-String -Pattern "\w" |
                ForEach-Object { $PSitem.ToString().Trim() })

    return $return
}
#endregion Support Functions
