Function Migrate-FirstVM ($VMHost,$Destination) {
$FirstVM = Get-ClusterNode -Cluster MSCL01 $VMHost | Get-ClusterGroup | ?{ $_ | Get-ClusterResource | ?{ $_.ResourceType -like "Virtual Machine" } } | Select-Object -First 1
$FirstVM | Move-ClusterVirtualMachineRole -Node $Destination | Out-Null
$Freemem = Get-WmiObject -Class Win32_OperatingSystem -Computername $Destination
"Free Memory (GB): {0}" -f ([math]::round(($freemem.FreePhysicalMemory / 1024 / 1024), 2))
}

Function Migrate-AllVMs ($VMHost,$Destination) {
$VMs = Get-ClusterNode -Cluster MSCL01 $VMHost | Get-ClusterGroup | ?{ $_ | Get-ClusterResource | ?{ $_.ResourceType -like "Virtual Machine" } }                        
$Freemem = Get-WmiObject -Class Win32_OperatingSystem -Computername $Destination
foreach ($VM in $VMs){
$VM | Move-ClusterVirtualMachineRole -Node $Destination | Out-Null
"Free Memory (GB): {0}" -f ([math]::round(($freemem.FreePhysicalMemory / 1024 / 1024), 2))
}
}

