Function   Provision-Host  ($Hostname, $BMCAddress, $CustomerID, $IPSubnet) {

###Test Cleanup

Get-SCUserRole -Name $CustomerID | Remove-SCUserRole
Get-SCCloud -Name $CustomerID | Remove-SCCloud
Get-SCStaticIPAddressPool -Name $CustomerID | Remove-SCStaticIPAddressPool
Get-SCVMNetwork -Name $CustomerID | Remove-SCVMNetwork
Get-SCLogicalNetworkDefinition -Name $CustomerID"_Network_0" | Remove-SCLogicalNetworkDefinition 
Get-SCLogicalNetwork -Name $CustomerID | Remove-SCLogicalNetwork
Get-SCVMHostGroup -Name $CustomerID | Remove-SCVMHostGroup

sleep 15

####Host Group Creation
    If (!(Get-SCVMHostGroup -Name $CustomerID)) {
    New-SCVMHostGroup -Name $CustomerID
                            }

####New Logical Network

    If (!(Get-SCLogicalNetwork -Name $CustomerID))  {
    $logicalNetwork = New-SCLogicalNetwork -Name $CustomerID -LogicalNetworkDefinitionIsolation $false -EnableNetworkVirtualization $false -UseGRE $false -IsPVLAN $false
    $allHostGroups = @()
    $allHostGroups += Get-SCVMHostGroup -name $CustomerID
    $allSubnetVlan = @()
    $allSubnetVlan += New-SCSubnetVLan -Subnet $IPSubnet -VLanID 0
    New-SCLogicalNetworkDefinition -Name $CustomerID"_Network_0" -LogicalNetwork $logicalNetwork -VMHostGroup $allHostGroups -SubnetVLan $allSubnetVlan -RunAsynchronously
                    }

###Create IP Pool
        If (!(Get-SCStaticIPAddressPool -Name $CustomerID)) {
        $logicalNetwork = Get-SCLogicalNetwork -Name $CustomerID
        $logicalNetworkDefinition = Get-SCLogicalNetworkDefinition -LogicalNetwork $logicalNetwork -Name $CustomerID"_Network_0"
        $allGateways = @()
        $allGateways += New-SCDefaultGateway -IPAddress ($IPSubnet.Substring(0,7)+1) -Automatic
        $allDnsServer = @("64.159.90.199", "64.159.90.200")
        $allDnsSuffixes = @()
        $allWinsServers = @()
    New-SCStaticIPAddressPool -Name $CustomerID -LogicalNetworkDefinition $logicalNetworkDefinition -Subnet $IPSubnet -IPAddressRangeStart ($IPSubnet.SubString(0,7)+10) -IPAddressRangeEnd ($IPSubnet.SubString(0,7)+254) -DefaultGateway $allGateways -DNSServer $allDnsServer -DNSSuffix "" -DNSSearchSuffix $allDnsSuffixes -RunAsynchronously        
                                        }
###Create VM Network
    If (!(Get-SCVMNetwork -Name $CustomerID))   {
    $logicalNetwork = Get-SCLogicalNetwork -Name $CustomerID 
    $vmNetwork = New-SCVMNetwork -Name $CustomerID -LogicalNetwork $logicalNetwork -IsolationType "NoIsolation"
    Write-Output $vmNetwork
                        }

###Create Cloud
        If (!(Get-SCCloud -Name $CustomerID))       {
    $CloudJobID = [System.Guid]::NewGuid()
    Set-SCCloudCapacity -JobGroup $CloudJobID -UseCustomQuotaCountMaximum $true -UseMemoryMBMaximum $true -UseCPUCountMaximum $true -UseStorageGBMaximum $true -UseVMCountMaximum $true
    $resources = @()
    $resources += Get-SCLogicalNetwork -Name $CustomerID
    $resources += Get-SCPortClassification -ID "12867374-6ec2-43e1-9aac-6f26bf5e7757"
    $readonlyLibraryShares = @()
    $readonlyLibraryShares += Get-SCLibraryShare -ID "fef171ce-853c-4983-b0c8-47dabfd9f5c7"
    Set-SCCloud -JobGroup $CloudJobID -RunAsynchronously -AddCloudResource $resources -AddReadOnlyLibraryShare $readonlyLibraryShares
    $hostGroups = @()
    $hostGroups += Get-SCVMHostGroup -name $CustomerID
    New-SCCloud -JobGroup $CloudJobID -VMHostGroup $hostGroups -Name $CustomerID -Description "" -RunAsynchronously
                                                }

###Create New SSU
    If (!(Get-SCUserRole -Name $CustomerID))    {
    $SSUJobID = [System.Guid]::NewGuid()
    $scopeToAdd = @()
    $scopeToAdd += Get-SCCloud -Name $CustomerID
    Set-SCUserRole -JobGroup $SSUJobID -AddScope $scopeToAdd -Permission @("Author", "AuthorVMNetwork", "Checkpoint", "CreateFromVHDOrTemplate", "AllowLocalAdmin", "PauseAndResume", "RemoteConnect", "Remove", "Save", "Shutdown", "Start", "Stop", "Store") -ShowPROTips $false -RemoveVMNetworkMaximumPerUser -RemoveVMNetworkMaximum
    $cloud = Get-SCCloud -Name $CustomerID
    Set-SCUserRoleQuota -Cloud $cloud -JobGroup $SSUJobID -UseCPUCountMaximum -UseMemoryMBMaximum -UseStorageGBMaximum -UseCustomQuotaCountMaximum -UseVMCountMaximum
    Set-SCUserRoleQuota -Cloud $cloud -JobGroup $SSUJobID -QuotaPerUser -UseCPUCountMaximum -UseMemoryMBMaximum -UseStorageGBMaximum -UseCustomQuotaCountMaximum -UseVMCountMaximum
    $libResource = Get-SCRunAsAccount -Name "RunAs"
    Grant-SCResource -Resource $libResource -JobGroup $SSUJobID
    $libResource = Get-SCVMNetwork -Name $CustomerID
    Grant-SCResource -Resource $libResource -JobGroup $SSUJobID
    $Templates = Get-SCVMTemplate
    Foreach ($Template in $Templates)   {
    $libResource = Get-SCVMTemplate -ID $Template.Id
    Grant-SCResource -Resource $libResource -JobGroup $SSUJobID
                        }
    New-SCUserRole -Name $CustomerID -UserRoleProfile "TenantAdmin" -Description "" -JobGroup $SSUJobID
                            }

####Host Provisioning
        $BMCRunAsAccount = Get-SCRunAsAccount BMCAdmin
        $Server = Find-SCComputer -BMCAddress $BMCAddress –BMCRunAsAccount $BMCRunAsAccount -BMCProtocol "IPMI" -DeepDiscovery
        $LogicalNetwork=Get-SCLogicalNetwork -name "LAN"
        $NetworkAdapterConfig = @()
        $Server.PhysicalMachine.NetworkAdapters | ForEach-Object {
        if      ($_.CommonDeviceName -eq "Ethernet")    {
        $NetworkAdapterConfig += New-SCVMHostNetworkAdapterConfig -SetAsPhysicalNetworkAdapter -SetAsManagementNIC -UseStaticIPForIPConfiguration -LogicalNetwork $LogicalNetwork -IPv4Subnet "10.140.143.1/24" -MACAddress $_.MacAddress
                                                        }
        Else    {
        $NetworkAdapterConfig += New-SCVMHostNetworkAdapterConfig -SetAsPhysicalNetworkAdapter -SetAsGenericNIC -UseStaticIPForIPConfiguration -LogicalNetwork $LogicalNetwork -IPv4Subnet "10.140.143.1/24" -MACAddress $_.MacAddress
                }
                                }
        $ComputerName = $Hostname
        $BMCRAA = Get-SCRunAsAccount -Name “BMCAdmin”
        $HostGroup = Get-SCVMHostGroup -Name $CustomerID
        $HostProfile = Get-SCVMHostProfile -Name "Private Cloud Host"
        $BootVolumeDisk=$Server.PhysicalMachine.Disks.DeviceName[0]
        $BMCHostConfiguration = New-SCVMHostConfig -BMCAddress $Server.BMCAddress -SMBiosGuid $Server.SMBIOSGUID -BMCPort 623 -BMCProtocol "IPMI" -BMCRunAsAccount $BMCRAA -BypassADMachineAccountCheck -ComputerName $ComputerName -Description "" -VMHostGroup $HostGroup -VMHostProfile $HostProfile -VMHostNetworkAdapterConfig $NetworkAdapterConfig -BootDiskVolume $BootVolumeDisk
        New-SCVMHost -VMHostConfig $BMCHostConfiguration -RunAsynchronously
}

Provision-Host -Hostname testhost01 -BMCAddress 10.140.143.232 -CustomerID TestCustomer01 -IPSubnet "10.1.1.1/24"