$VMList = Import-CSV C:\VMList.csv
$VMs = $VMList | foreach {$_.VMName}

Function Make-VM {
mkdir C:\VMs\$VM
New-VM –Name $VM –MemoryStartupBytes 1024MB -SwitchName “New Virtual Switch” -Path C:\VMs\$VM | Out-Null
New-VHD –ParentPath T:\02R2June2012\08R2TemplateJune2012.vhdx –Path C:\VMs\$VM\$VM.vhdx -Differencing
Add-VMHardDiskDrive $VM -Path C:\VMs\$VM\$VM.vhdx
}

Foreach ($VM in $VMs) {
        $VMStatus = Get-VM $VM
        If (!$VMStatus) {
        Make-VM
        }
        Else{
        Write-Host "There is already a VM with that Name"
        }
        }
}

-------------------------------------------------------------------------------------------------------------------

$VMList = Import-CSV C:\VMList.csv
$VMs = $VMList | foreach {$_.VMName}
$VMIPs = $VMList | foreach {$_.VMIP}

Foreach ($VMIP in $VMIPs) {
        $UserStatus = Get-TSSession -ComputerName $VMIP | Where-Object {$_.State -eq "Active"}
        If (!$UserStatus) {
        Shutdown-VM $VM
        Restore-VMSnapshot -VMName $VM -VMSnapshot "Default"
        Start-VM $VM
        }
}
