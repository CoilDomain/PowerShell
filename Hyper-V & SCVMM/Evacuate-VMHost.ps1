Function Migrate-FirstVM ($VMHost) {
$VMs = Get-ClusterNode -Cluster MSCL01 $VMHost | Get-ClusterGroup | ?{ $_ | Get-ClusterResource | ?{ $_.ResourceType -like "Virtual Machine" 
} }                        
foreach ($VM in $VMs){
Write-Host $VM.Name
$Destination = Get-VMHost | Where-Object {$_.Name -notlike $VMHost+".domain.tld" -and $_.Name -notlike "inf*" -and $_.AvailableForPlacement -match "True"} | select name,availablememory | Sort-Object -Property availablememory -Descending | select -First 1
sleep 10
$VM | Move-ClusterVirtualMachineRole -Node $Destination.name | Out-Null
}
}
