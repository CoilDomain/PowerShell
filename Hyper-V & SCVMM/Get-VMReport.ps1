Function Get-VMReport ($Server) {
$FullReport=@()

$VMHosts=Get-SCVMHost -VMMServer $Server
$VMHosts | Foreach {
$Memory=$_.TotalMemory / 1gb
$FreeMemory=$_.AvailableMemory / 1024
$TotalStorage=$_.LocalStorageTotalCapacity / 1gb
$FreeStorage=$_.LocalStorageAvailableCapacity / 1gb
$VMCount=($_ | Get-SCVirtualMachine).Count
$CPUAllocation=($_  | Get-SCVirtualMachine | Measure-Object -Property cpucount -sum).Sum
$StorageAllocation=($_ | Get-SCVirtualMachine | Get-SCVirtualHardDisk | Measure-Object -Property MaximumSize -Sum).sum / 1gb
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "VM Count" -value $VMCount
	$Report | Add-Member -Type NoteProperty -Name "Logical CPU Cores" -Value $_.LogicalProcessorCount
	$Report | Add-Member -Type NoteProperty -Name "Virtual CPU Cores" -Value $CPUAllocation
	$Report | Add-Member -Type NoteProperty -Name "Physical Memory GB" -Value ([math]::Round($Memory))
	$Report | Add-Member -Type NoteProperty -Name "Free Memory GB" -Value ([math]::Round($FreeMemory))
	$Report | Add-Member -Type NoteProperty -Name "Physical Disk GB" -value ([math]::Round($TotalStorage))
	$Report | Add-Member -Type NoteProperty -Name "Free Disk Space GB" -value ([math]::Round($FreeStorage))
	$Report | Add-Member -Type NoteProperty -Name "Total Allocated Space GB" -value ([math]::Round($StorageAllocation))
	$FullReport+=$Report	
}
$FullReport | Sort-Object -Property Name
}