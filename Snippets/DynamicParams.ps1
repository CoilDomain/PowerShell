function Foo() {
    [CmdletBinding()]
    Param ()
    DynamicParam {
        $TemplatesAttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

        # [parameter(mandatory=...,
        #     ...
        # )]
        $TemplatesParameterAttribute = new-object System.Management.Automation.ParameterAttribute
        $TemplatesParameterAttribute.Mandatory = $true
        $TemplatesParameterAttribute.HelpMessage = "Enter A Template name"
        $TemplatesAttributeCollection.Add($TemplatesParameterAttribute)    

        # [ValidateSet[(...)]
        $TemplatesNames = @()
        foreach($TemplatesInfo in Get-SCVMTemplate) {
            $TemplatesNames += $TemplatesInfo.Name
        }
        $TemplatesValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($TemplatesNames)
        $TemplatesAttributeCollection.Add($TemplatesValidateSetAttribute)

        # Remaining boilerplate
        $TemplatesRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Template", [String[]], $TemplatesAttributeCollection)

        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("Template", $TemplatesRuntimeDefinedParam)
        return $paramDictionary
    }
}