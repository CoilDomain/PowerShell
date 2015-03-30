Function Set-TSProfilePath ($Username, $SharePath) {
$user=Get-ADUser $Username
$parent=(($user.DistinguishedName | %{$_.split(',')[1]}).replace('OU=','')).replace(' ','')
$directory=$SharePath+$parent+"\"+$user.SamAccountName
$DistinguishedName=$user.DistinguishedName | out-string
$Object = [adsi]"LDAP://$DistinguishedName"
$Object.psbase.invokeSet("TerminalServicesProfilePath",$directory)
$Object.setinfo()
}