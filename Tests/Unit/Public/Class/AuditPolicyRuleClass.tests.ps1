#########################################      Header      #########################################
using module ..\..\..\..\src\public\class\AuditPolicyRuleClass.psm1
. $PSScriptRoot\..\..\..\helper.ps1
$ruleClassName = ($MyInvocation.MyCommand.Name -Split '\.')[0]
#########################################      Header      #########################################
#########################################    Test Setup    #########################################
$rule = [AuditPolicyRule]::new( (Get-TestStigRule -ReturnGroupOnly) )

$checkContentBase = 'Security Option "Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings" must be set to "Enabled" (V-14230) for the detailed auditing subcategories to be effective. 

Use the AuditPol tool to review the current Audit Policy configuration:
-Open a Command Prompt with elevated privileges ("Run as Administrator").
-Enter "AuditPol /get /category:*".

Compare the AuditPol settings with the following.  If the system does not audit the following, this is a finding.

{0}'
#########################################    Test Setup    #########################################
#########################################    Class Tests   #########################################
Describe "$ruleClassName Child Class" {

    Context 'Base Class' {
        
        It "Shoud have a BaseType of STIG" {
            $rule.GetType().BaseType.ToString() | Should Be 'STIG'
        }
    }

    Context 'Class Properties' {
        
        $classProperties = @('Subcategory', 'AuditFlag', 'Ensure')

        foreach ( $property in $classProperties )
        {
            It "Should have a property named '$property'" {
                ( $rule | Get-Member -Name $property ).Name | Should Be $property
            }
        }
    }

    Context 'Class Methods' {
        
        $classMethods = @('SetSubcategory', 'SetAuditFlag', 'SetEnsureFlag')

        foreach ( $method in $classMethods )
        {
            It "Should have a method named '$method'" {
                ( $rule | Get-Member -Name $method ).Name | Should Be $method
            }
        }

        # If new methods are added this will catch them so test coverage can be added
        It "Should not have more methods than are tested" {
            $memberPlanned = Get-StigBaseMethods -ChildClassMethodNames $classMethods
            $memberActual = ( $rule | Get-Member -MemberType Method ).Name
            $compare = Compare-Object -ReferenceObject $memberActual -DifferenceObject $memberPlanned
            $compare.Count | Should Be 0
        }
    }
}
#########################################    Class Tests   #########################################
###################################### Method function Tests #######################################
$string = 'Account Management -> Computer Account Management - Success'

Describe 'Get-AuditPolicySettings' {

    Context 'Data format "->"' { 

        $checkContent = ($checkContentBase -f $string) -split '\n' 
        $settings = Get-AuditPolicySettings -CheckContent $checkContent

        It 'Should return the Category in the first index' {
            $settings[0] | Should Match '(\s)*Account Management(\s)*'
        }
        It 'Should return the SubCategory in the second index' {
            $settings[1] | Should Match '(\s)*Computer Account Management(\s)*'
        }
        It 'Should return the audit flag in the third index' {
            $settings[2] | Should Match '(\s)*Success(\s)*'
        }
    }

    Context 'Data format ">>"' {

        $string = 'Account Management >> Computer Account Management - Success'
        $checkContent = ($checkContentBase -f $string) -split '\n' 
        $settings = Get-AuditPolicySettings -CheckContent $checkContent

        It 'Should return the Category in the first index' {
            $settings[0] | Should Match '(\s)*Account Management(\s)*'
        }
        It 'Should return the SubCategory in the second index' {
            $settings[1] | Should Match '(\s)*Computer Account Management(\s)*'
        }
        It 'Should return the audit flag in the third index' {
            $settings[2] | Should Match '(\s)*Success(\s)*'
        }
    }
}

Describe 'Get-AuditPolicySubCategory' {

    #Mock -CommandName Get-AuditPolicySettings -MockWith { @('Category ', ' Subcategory ', ' Flag') }
    $checkContent = ($checkContentBase -f $string) -split '\n'
    It 'Should return the second string in quotes' {
        Get-AuditPolicySubCategory -CheckContent $checkContent | Should Be 'Computer Account Management'
    }
}

Describe 'Get-AuditPolicyFlag' {
    
    #Mock -CommandName Get-AuditPolicySettings -MockWith { @('Category ', ' Subcategory ', ' Flag') }
    $checkContent = ($checkContentBase -f $string) -split '\n'
    It 'Should return the audit policy flag' {
        Get-AuditPolicyFlag -CheckContent $checkContent | Should Be 'Success'
    }
}
###################################### Method function Tests #######################################
