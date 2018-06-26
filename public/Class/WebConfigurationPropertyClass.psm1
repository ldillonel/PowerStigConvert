# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

#region Header
using module .\StigClass.psm1
using module ..\common\enum.psm1

. $PSScriptRoot\..\common\data.ps1
. $PSScriptRoot\..\data\data.Web.ps1
#endregion
#region Class Definition
Class WebConfigurationPropertyRule : STIG
{
    [string] $ConfigSection
    [string] $Key
    [string] $Value

    # Constructors
    WebConfigurationPropertyRule ( [xml.xmlelement] $StigRule )
    {
        $this.InvokeClass( $StigRule )
    }

    # Methods
    [void] SetConfigSection ( )
    {
        $thisConfigSection = Get-ConfigSection -CheckContent $this.SplitCheckContent

        if ( -not $this.SetStatus( $thisConfigSection ) )
        {
            $this.set_ConfigSection( $thisConfigSection )
        }
    }

    [void] SetKeyValuePair ( )
    {
        $thisKeyValuePair = Get-KeyValuePair -CheckContent $this.SplitCheckContent

        if ( -not $this.SetStatus( $thisKeyValuePair ) )
        {
            $this.set_Key( $thisKeyValuePair.Key )
            $this.set_Value( $thisKeyValuePair.Value )
        }
    }

    [Boolean] IsOrganizationalSetting ( )
    {
        if ( -not [String]::IsNullOrEmpty( $this.key ) -and [String]::IsNullOrEmpty( $this.value ) )
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    [void] SetOrganizationValueTestString ( )
    {
        $thisOrganizationValueTestString = Get-OrganizationValueTestString -Key $this.key

        if ( -not $this.SetStatus( $thisOrganizationValueTestString ) )
        {
            $this.set_OrganizationValueTestString( $thisOrganizationValueTestString )
            $this.set_OrganizationValueRequired( $true )
        }
    }

    static [bool] HasMultipleRules ( [string] $CheckContent )
    {
        return Test-MultipleWebConfigurationPropertyRule -CheckContent ( [STIG]::SplitCheckContent( $CheckContent ) )
    }

    static [string[]] SplitMultipleRules ( [string] $CheckContent )
    {
        return ( Split-MultipleWebConfigurationPropertyRule -CheckContent ( [STIG]::SplitCheckContent( $CheckContent ) ) )
    }
}
#endregion
#region Method Function
<#
.SYNOPSIS
    Returns the ConfigSection property for the STIG rule.

.Parameter CheckContent
    An array of the raw string data taken from the STIG setting.
#>
Function Get-ConfigSection
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $CheckContent
    )

    $cleanCheckContent = $CheckContent -replace $script:webRegularExpression.excludeExtendedAscii, '"'

    switch ($cleanCheckContent)
    {
        { $PSItem -match $script:webRegularExpression.configSection }
        {
            $matchConfigSection = $PSItem | Select-String -Pattern $script:webRegularExpression.configSection -AllMatches
            $configSection = $matchConfigSection.Matches.Groups.Value -replace " ", "/"

            if ( -not $configSection.StartsWith("/") )
            {
                $configSection = "/" + $configSection
            }
        }
        { $cleanCheckContent -match 'Directory Browsing' }
        {
            $configSection = '/system.webServer/directoryBrowse'
        }
        { $cleanCheckContent -match '\.NET Trust Level' }
        {
            $configSection = '/system.web/trust'
        }
        { $cleanCheckContent -match 'SSL Settings' }
        {
            $configSection = '/system.webServer/security/access'
        }
        { $cleanCheckContent -match '\.NET Compilation' }
        {
            $configSection = '/system.web/compilation'
        }
        { $cleanCheckContent -match 'maxUrl|maxAllowedContentLength|Maximum Query String' }
        {
            $configSection = '/system.webServer/security/requestFiltering/requestlimits'
        }
        { $cleanCheckContent -match 'Allow high-bit characters|Allow double escaping' }
        {
            $configSection = '/system.webServer/security/requestFiltering'
        }
        { $cleanCheckContent -match 'Allow unlisted file extensions' }
        {
            $configSection = '/system.webServer/security/requestFiltering/fileExtensions'
        }
        { $cleanCheckContent -match 'Error Pages' }
        {
            $configSection = '/system.webServer/httpErrors'
        }
        { $cleanCheckContent -match 'keepSessionIdSecure' }
        {
            $configSection = '/system.webServer/asp/session'
        }
    }

    if ($null -ne $configSection)
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] Found ConfigSection: $($configSection)"
        return $configSection
    }
    else
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] ConfigSection not found"
        return $null
    }
}

<#
.SYNOPSIS
    Returns the key and value properties for the STIG rule.

.Parameter CheckContent
    An array of the raw string data taken from the STIG setting.
#>
function Get-KeyValuePair
{
    [CmdletBinding()]
    [OutputType([object])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $CheckContent
    )

    switch ( $CheckContent )
    {
        { $PSItem -match $script:webRegularExpression.keyValuePairLine }
        {
            [string] $matchKeyValuePairLine = $PsItem | Select-String -Pattern $script:webRegularExpression.keyValuePairLine -AllMatches

            $keyValuePair = $matchKeyValuePairLine | Select-String -Pattern $script:webRegularExpression.keyValuePair -AllMatches

            $key   = ($keyValuePair.Matches.Groups.value[0]).replace(' ','')
            $value = $keyValuePair.Matches.Groups.value[-1]
        }
        { $CheckContent -match 'Directory Browsing' }
        {
            $key   = 'enabled'
            $value = 'false'
        }
        { $CheckContent -match 'SSL Settings' }
        {
            $key   = 'sslflags'
            $value = 'Ssl,SslNegotiateCert,SslRequireCert,Ssl128'
        }
        { $CheckContent -match '\.NET Compilation' }
        {
            $key   = 'debug'
            $value = 'false'
        }
        { $CheckContent -match 'Allow high-bit characters' }
        {
            $key   = 'allowHighBitCharacters'
            $value = 'false'
        }
        { $CheckContent -match 'Allow double escaping' }
        {
            $key   = 'allowDoubleEscaping'
            $value = 'false'
        }
        { $CheckContent -match 'Allow unlisted file extensions' }
        {
            $key   = 'allowUnlisted'
            $value = 'false'
        }
        { $CheckContent -match 'maxUrl' }
        {
            $key   = 'maxUrl'
            $value = $null
        }
        { $CheckContent -match 'maxAllowedContentLength' }
        {
            $key   = 'maxAllowedContentLength'
            $value = $null
        }
        { $CheckContent -match 'Maximum Query String' }
        {
            $key   = 'maxQueryString'
            $value = $null
        }
        { $CheckContent -match 'Error Pages' }
        {
            $key   = 'errormode'
            $value = 'DetailedLocalOnly'
        }
        { $CheckContent -match '\.NET Trust Level' }
        {
            $key   = 'level'
            $value = $null
        }
        { $CheckContent -match 'Verify the "timeout" is set' }
        {
            $key   = 'timeout'
            $value = $null
        }
    }
    if ($null -ne $key)
    {
        Write-Verbose -Message $("[$($MyInvocation.MyCommand.Name)] Found Key: {0}, value: {1}" -f $key, $value)

        return @{
            key   = $key
            value = $value
        }
    }
    else
    {
        Write-Verbose -Message "[$($MyInvocation.MyCommand.Name)] No Key or Value found"
        return $null
    }
}

<#
.SYNOPSIS
    Tests to see if the stig rule needs to be split into multiples.

.Parameter CheckContent
    An array of the raw string data taken from the STIG setting.
#>
function Test-MultipleWebConfigurationPropertyRule
{
    [CmdletBinding()]
    [OutputType( [bool] )]
    Param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $CheckContent
    )

    $matchConfigSection = $CheckContent | Select-String -Pattern $script:webRegularExpression.configSection -AllMatches

    if ($matchConfigSection.Count -gt 1)
    {
        Write-Verbose -message "[$($MyInvocation.MyCommand.Name)] : $true"
        return $true
    }
    else
    {
        Write-Verbose -message "[$($MyInvocation.MyCommand.Name)] : $false"
        return $false
    }
}

<#
.SYNOPSIS
    Splits a STIG setting into multiple rules when necessary.

.Parameter CheckContent
    An array of the raw string data taken from the STIG setting.
#>
function Split-MultipleWebConfigurationPropertyRule
{
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $CheckContent
    )

    $splitWebConfigurationPropertyRules = @()

    foreach ($line in $CheckContent)
    {
        if ($line -match $script:webRegularExpression.configSection)
        {
            $webConfigurationPropertyRule = @()
            $webConfigurationPropertyRule +=  $line
        }
        if ($line -match $script:webRegularExpression.keyValuePairLine)
        {
            $webConfigurationPropertyRule +=  $line
            $splitWebConfigurationPropertyRules += ($webConfigurationPropertyRule -join "`r`n")
        }
    }

    return $splitWebConfigurationPropertyRules
}

<#
.SYNOPSIS
    Takes the key property from a WebConfigurationPropertyRule to determine the Organizational value
    test string to return.

.PARAMETER Key
    Key property from the WebConfigurationPropertyRule.
#>
function Get-OrganizationValueTestString
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Key
    )

    switch ( $Key )
    {
        { $PsItem -match 'maxUrl' }
        {
            return '{0} -le 4096'
        }
        { $PsItem -match 'maxAllowedContentLength' }
        {
            return '{0} -le 30000000'
        }
        { $PsItem -match 'maxQueryString' }
        {
            return '{0} -le 2048'
        }
        { $PsItem -match 'level' }
        {
            return "'{0}' -cmatch '^(Full|High)$'"
        }
        { $PsItem -match 'timeout' }
        {
            return "[TimeSpan]{0} -le [TimeSpan]'00:20:00'"
        }
        default
        {
            return $null
        }
    }
}
#endregion
