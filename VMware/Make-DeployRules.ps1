Function Make-DeployRules	{
    If (!(Get-EsxSoftwareDepot))    {
        Add-EsxSoftwareDepot -DepotUrl https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
    }

    $Image = Get-ESXImageProfile -Name "ESXi-5.1.0-20130402001-standard"
    $InfProfile = Get-VMHostProfile -Name vCloud-Inf
    $HostProfile = Get-VMHostProfile -Name vCloud-Host
    $InfCluster = Get-Cluster -Name Infrastructure
    $HostCluster = Get-Cluster -Name Hosts
    $BootNetwork = "Private"
	
    $VMs = Get-VM | Where-Object {$_.Name -like "vCloud*"}

	Foreach ($VM in $VMs)	{
    $MacAddress = "mac="
    $MacAddress += (Get-VM $VM | Get-NetworkAdapter | Where-Object {$_.NetworkName -match $BootNetwork}).MacAddress

    If ($VM.Name -like "vCloud-Inf*")   {
        New-DeployRule -Name $VM.Name -Pattern $MacAddress -Item $Image, $InfProfile, $InfCluster | Add-DeployRule
    }
    ElseIf ($VM.Name -like "vCloud-Host*")  {
        New-DeployRule -Name $VM.Name -Pattern $MacAddress -Item $Image, $HostProfile, $HostCluster | Add-DeployRule
    }
	}
}
