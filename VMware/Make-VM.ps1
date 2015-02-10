function Make-VM ($VMName, $IP) {
$template = "Win2008R2"
$Pool = Get-ResourcePool "Resources"
$Datastore = get-datastore -name "OpenFiler"
$OSCustomizationSpec = get-OSCustomizationSpec "Windows"
####All Other VM based parameters are stored in the template and template spec#####
$NetMask = "255.255.255.0"
$Gateway = "10.0.0.1"
$DNS = "10.0.0.100"
####Assign IP address to Template####
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
		New-VM -Name ($VMName + $_) `
		-Template $template `
		-ResourcePool $Pool `
		-Datastore $datastore `
		-OSCustomizationSpec $OSCustomizationSpec
		#Start-VM -VM ($VMName + $_)
}
Deploy
}