Function Set-IP ($VMName, $IP, $StaticIPPool) {
$VM = Get-SCVirtualMachine -Name "$VMName"
$vNICs = $VM.VirtualNetworkAdapters
$IPPool = Get-SCStaticIPAddressPool -Name $StaticIPPool
Grant-SCIPAddress -StaticIPAddressPool $IPPool -GrantToObjectType VirtualNetworkAdapter -GrantToObjectID $vNICs[0].ID -Description $VM.Name -IP $IP
}

