function Foo() {
    [CmdletBinding()]
    Param ()
    DynamicParam {
        $TemplatesAttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $NetworksAttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $IPAddresssAttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

        $TemplatesParameterAttribute = new-object System.Management.Automation.ParameterAttribute
        $TemplatesParameterAttribute.Mandatory = $true
        $TemplatesParameterAttribute.HelpMessage = "Enter A Template name"
        $TemplatesAttributeCollection.Add($TemplatesParameterAttribute)    
        $NetworksParameterAttribute = new-object System.Management.Automation.ParameterAttribute
        $NetworksParameterAttribute.Mandatory = $true
        $NetworksParameterAttribute.HelpMessage = "Enter A Network name"
        $NetworksAttributeCollection.Add($NetworksParameterAttribute)  
        $IPAddresssParameterAttribute = new-object System.Management.Automation.ParameterAttribute
        $IPAddresssParameterAttribute.Mandatory = $true
        $IPAddresssParameterAttribute.HelpMessage = "Enter A IP Address"
        $IPAddresssAttributeCollection.Add($IPAddresssParameterAttribute) 

        $TemplatesNames = @()
        foreach($TemplatesInfo in Get-SCVMTemplate) {
            $TemplatesNames += $TemplatesInfo.Name
        }
                $NetworksNames = @()
        foreach($NetworksInfo in Get-SCVMNetwork) {
            $NetworksNames += $NetworksInfo.Name
        }
        $IPAddresssNames = @()
        foreach($IPAddresssInfo in Get-SCIPAddress) {
            $IPAddresssNames += $IPAddresssInfo.Name
        }

        $TemplatesValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($TemplatesNames)
        $TemplatesAttributeCollection.Add($TemplatesValidateSetAttribute)
        $NetworksValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($NetworksNames)
        $NetworksAttributeCollection.Add($NetworksValidateSetAttribute)
        $IPAddresssValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($IPAddresssNames)
        $IPAddresssAttributeCollection.Add($IPAddresssValidateSetAttribute)

        $TemplatesRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Template", [String[]], $TemplatesAttributeCollection)
        $NetworksRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Network", [String[]], $NetworksAttributeCollection)
        $IPAddresssValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($IPAddresssNames)
        $IPAddresssAttributeCollection.Add($IPAddresssValidateSetAttribute)
        $IPAddresssRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("IPAddress", [String[]], $IPAddresssAttributeCollection)

        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("Template", $TemplatesRuntimeDefinedParam)
        $paramDictionary.Add("Network", $NetworksRuntimeDefinedParam)
        $paramDictionary.Add("IPAddress", $IPAddresssRuntimeDefinedParam)

        return $paramDictionary
    }
    Process {
$paramDictionary.Network.Value
    }
}