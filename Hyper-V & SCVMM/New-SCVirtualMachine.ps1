Function New-SCVM ()	{

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

$VMJobGroup = [System.Guid]::NewGuid()

New-SCVirtualScsiAdapter -VMMServer localhost -JobGroup $VMJobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 
New-SCVirtualDVDDrive -VMMServer localhost -JobGroup $VMJobGroup -Bus 1 -LUN 0 
$VMNetwork = Get-SCVMNetwork | Where-Object {$_.Name -match "$paramDictionary.Network.Value"}
New-SCVirtualNetworkAdapter -VMMServer localhost -JobGroup $VMJobGroup -MACAddress "00-00-00-00-00-00" -MACAddressType Static -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -IPv4AddressType Static -IPv6AddressType Dynamic -VMNetwork $VMNetwork 

Set-SCVirtualCOMPort -NoAttach -VMMServer localhost -GuestPort 1 -JobGroup $VMJobGroup 

Set-SCVirtualCOMPort -NoAttach -VMMServer localhost -GuestPort 2 -JobGroup $VMJobGroup 

Set-SCVirtualFloppyDrive -RunAsynchronously -VMMServer localhost -NoMedia -JobGroup $VMJobGroup 
$CPUType = Get-SCCPUType -VMMServer localhost | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}

New-SCHardwareProfile -VMMServer localhost -CPUType $CPUType -Name $VMJobGroup -Description "Profile used to create a VM/Template" -CPUCount 1 -MemoryMB 2048 -DynamicMemoryEnabled $false -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $false -DRProtectionRequired $false -NumLock $false -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" -CPULimitFunctionality $false -CPULimitForMigration $false -JobGroup $VMJobGroup 

$Template = Get-SCVMTemplate -VMMServer localhost | where {$_.Name -eq $paramDictionary.Template.Value}
$HardwareProfile = Get-SCHardwareProfile -VMMServer localhost | where {$_.Name -eq $VMJobGroup}
$LocalAdministratorCredential = get-scrunasaccount -VMMServer "localhost" -Name "RunAs" -ID "7cb3df91-5aca-43b1-9d9a-6041f86c2161" ### Fix

$OperatingSystem = Get-SCOperatingSystem -VMMServer localhost  | where {$_.Name -eq "64-bit edition of Windows Server 2012 R2 Standard"}

New-SCVMTemplate -Name $VMJobGroup -Template $Template -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -ComputerName "$VMName" -TimeZone 35 -LocalAdministratorCredential $LocalAdministratorCredential  -AnswerFile $null -OperatingSystem $OperatingSystem 

$template = Get-SCVMTemplate -All | where { $_.Name -eq $VMJobGroup }
$virtualMachineConfiguration = New-SCVMConfiguration -VMTemplate $template -Name "test"
Write-Output $virtualMachineConfiguration
$VMHostGroup = Get-SCVMHostGroup
$vmHost = Get-SCVMHostRating -VMHostGroup $VMHostGroup -HardwareProfile $HardwareProfile -DiskSpaceGB 40 -VMName $VMName -CPUPriority 8 -MemoryPriority 5 -DiskPriority 3 -NetworkPriority 1 -ReturnFirstSuitableHost
Set-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration -VMHost $vmHost
Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration

$NICConfiguration = Get-SCVirtualNetworkAdapterConfiguration -VMConfiguration $virtualMachineConfiguration | where { $_.ID -eq "d519c709-e800-4105-bce5-dccdeedce03a" } ### Replace network
$staticIPv4Pool = Get-SCStaticIPAddressPool -Name "External VMs" -ID "d4997482-b9de-46b4-a82e-deb59025a5a1" ### Replace IP Pool
$macAddressPool = Get-SCMACAddressPool -Name "Default MAC address pool"
Set-SCVirtualNetworkAdapterConfiguration -VirtualNetworkAdapterConfiguration $NICConfiguration -IPv4Address "$IPAddress" -IPv4AddressPool $staticIPv4Pool -PinIPv4AddressPool $true -IPv6Address "" -PinIPv6AddressPool $false -MACAddress "" -MACAddressPool $macAddressPool


Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration
New-SCVirtualMachine -Name $VMName -VMConfiguration $virtualMachineConfiguration -Description "" -BlockDynamicOptimization $false -JobGroup "$VMJobGroup" -ReturnImmediately -StartAction "NeverAutoTurnOnVM" -StopAction "SaveVM"
Remove-SCHardwareProfile $HardwareProfile
Remove-SCVMTemplate $template
}
}
