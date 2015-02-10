$VMTemplateGUIDGroup = @()
$VMMServer = Get-VMMServer
1..10 | Foreach {


$VMJobGroup = [System.Guid]::NewGuid()
$VMTemplateGUID = [System.Guid]::NewGuid()
$VMHardwareProfileGUID = [System.Guid]::NewGuid()


New-SCVirtualScsiAdapter -VMMServer $VMMServer -JobGroup $VMJobGroup -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType 


New-SCVirtualDVDDrive -VMMServer $VMMServer -JobGroup $VMJobGroup -Bus 1 -LUN 0 


New-SCVirtualNetworkAdapter -VMMServer $VMMServer -JobGroup $VMJobGroup -Synthetic 


Set-SCVirtualCOMPort -NoAttach -VMMServer $VMMServer -GuestPort 1 -JobGroup $VMJobGroup 


Set-SCVirtualCOMPort -NoAttach -VMMServer $VMMServer -GuestPort 2 -JobGroup $VMJobGroup 


Set-SCVirtualFloppyDrive -RunAsynchronously -VMMServer $VMMServer -NoMedia -JobGroup $VMJobGroup 

$CPUType = Get-SCCPUType -VMMServer $VMMServer | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}


New-SCHardwareProfile -VMMServer $VMMServer -CPUType $CPUType -Name "$VMHardwareProfileGUID" -Description "Profile used to create a VM/Template" -CPUCount 1 -MemoryMB 4096 -DynamicMemoryEnabled $false -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $true -HAVMPriority 2000 -DRProtectionRequired $false -NumLock $false -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" -CPULimitFunctionality $false -CPULimitForMigration $false -Generation 1 -JobGroup $VMJobGroup 



$VirtualHardDisk = Get-SCVirtualHardDisk -VMMServer $VMMServer | where {$_.Location -eq "\\lib-c01-tpa02.cl.hostwaycloud.com\Smart_Cloud_Library\40GB_Windows 2012 Std CDP4 SQL12Web 09-17-12\40GB_Windows 2012 Std CDP4 SQL12Web 09-17-12.vhd"} | where {$_.HostName -eq "lib-c01-tpa02.cl.hostwaycloud.com"}

New-SCVirtualDiskDrive -VMMServer $VMMServer -IDE -Bus 0 -LUN 0 -JobGroup $VMJobGroup -CreateDiffDisk $false -VirtualHardDisk $VirtualHardDisk -FileName "test_40GB_Windows 2012 Std CDP4 SQL12Web 09-17-12.vhd" -VolumeType BootAndSystem 

$HardwareProfile = Get-SCHardwareProfile -VMMServer $VMMServer | where {$_.Name -eq "$VMHardwareProfileGUID"}

New-SCVMTemplate -Name "$VMTemplateGUID" -Generation 1 -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -NoCustomization 



$template = Get-SCVMTemplate -All | where { $_.Name -eq "$VMTemplateGUID" }
$virtualMachineConfiguration = New-SCVMConfiguration -VMTemplate $template -Name "test"
Write-Output $virtualMachineConfiguration
$VMHostGroup = Get-SCVMHostGroup
$vmHost = Get-SCVMHostRating -VMHostGroup $VMHostGroup -HardwareProfile $HardwareProfile -DiskSpaceGB 40 -VMName "test-$_" -CPUPriority 8 -MemoryPriority 5 -DiskPriority 3 -NetworkPriority 1 -ReturnFirstSuitableHost
Set-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration -VMHost $vmHost.name
Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration
Set-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration -VMLocation "C:\ClusterStorage\Volume3\" -PinVMLocation $true

$AllNICConfigurations = Get-SCVirtualNetworkAdapterConfiguration -VMConfiguration $virtualMachineConfiguration



Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration
$operatingSystem = Get-SCOperatingSystem | where { $_.Name -eq "Windows Server 2012 R2 Standard" }
New-SCVirtualMachine -Name "test-$_" -VMConfiguration $virtualMachineConfiguration -Description "" -BlockDynamicOptimization $false -StartVM -JobGroup "$VMJobGroup" -ReturnImmediately -StartAction "NeverAutoTurnOnVM" -StopAction "SaveVM" -OperatingSystem $operatingSystem
$VMTemplateGUIDGroup += $VMTemplateGUIDGroup + "$VMTemplateGUID"
}

Function Remove-GroupTemplate {
If ((Get-SCVirtualMachine | Where-Object {$_.Name -like "test-*" -and $_.status -match "Running"})) {
$VMTemplateGUIDGroup | Foreach {Get-SCVMTemplate -Name $_ | Remove-SCVMTemplate}
}
Else {
Sleep 30
Remove-GroupTemplate
}
}
Remove-GroupTemplate
