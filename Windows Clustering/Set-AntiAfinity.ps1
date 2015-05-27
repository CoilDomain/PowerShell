$VMs=(get-scvirtualmachine).name.trim('1', ' ').trim('0', ' ').trim('2', ' ').trim('0', ' ') 
Foreach ($VM in $VMs){
Get-SCVirtualMachine | Where-object {$_.name -like "$VM*"} | Foreach {
$value = New-Object System.Collections.Specialized.StringCollection
$value.Add($VM)
(Get-ClusterGroup -Cluster "Cluster" "SCVMM $_ Resources").AntiAffinityClassNames = $value
}
}