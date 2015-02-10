function Make-VM ($Template, $VMName, $IP) {
$Pool = Get-ResourcePool "Resources"
$Datastore = get-datastore -name "RAID"
####All Other VM based parameters are stored in the template and template spec#####
$NetMask = "255.255.255.0"
$Gateway = "10.0.0.1"
$DNS = "10.0.0.10"
####Assign IP address to Template####
if ($Template -match "Windows") {
$OSCustomizationSpec = get-OSCustomizationSpec "Windows"
function SetIP {
		get-OSCustomizationSpec "Windows" | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
		-IpMode UseStaticIP `
		-IpAddress $IP `
		-SubnetMask $NetMask `
		-DefaultGateway $Gateway `
		-Dns $DNS
		}
####Deployment####
Function Deploy {
		$OSCustomizationSpec | SetIP
		New-VM -Name $VMName `
		-Template $template `
		-ResourcePool $Pool `
		-Datastore $datastore `
		-OSCustomizationSpec $OSCustomizationSpec
		#Start-VM -VM $VMName
}
Deploy | Out-Null
}


elseif ($Template -match "CentOS") {
$OSCustomizationSpec = get-OSCustomizationSpec "CentOS"
function SetIP {
		get-OSCustomizationSpec "CentOS" | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping `
		-IpMode UseStaticIP `
		-IpAddress $IP `
		-SubnetMask $NetMask `
		-DefaultGateway $Gateway `
		}
####Deployment####
Function Deploy {
		$OSCustomizationSpec | SetIP
		New-VM -Name $VMName `
		-Template $template `
		-ResourcePool $Pool `
		-Datastore $datastore `
		-OSCustomizationSpec $OSCustomizationSpec
		Start-VM -VM $VMName
}
Deploy | Out-Null
}
}
