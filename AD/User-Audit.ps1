$HostingOUs="ArrayItem1", "ArrayItem2"

Foreach ($OU in $HostingOUs) {

$CompanyOUs=Get-OrganizationalUnit $OU -SingleNodeOnly | Where-Object {$_.Name -notmatch $OU}
Foreach ($CompanyOU in $CompanyOUs) {
$OutFile=$CompanyOU.Name.Replace(" ", "")
$Users=Get-ADUser -filter 'enabled -eq $true' -Property * | Where-object {$_.DistinguishedName -match $CompanyOU.DistinguishedName}
$FullReport=@()
$Users | Foreach {
	$ErrorActionPreference = "silentlycontinue"
	$DistinguishedName=$_.DistinguishedName | out-string
	$Object = [adsi]"LDAP://$DistinguishedName"
	$Object.psbase.invokeget(“TerminalServicesProfilePath“)
	$Mailbox=Get-Mailbox $_.SamAccountName -ErrorAction SilentlyContinue
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name UserName -Value $_.SamAccountName
	If (($Mailbox)){$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $Mailbox.PrimarySMTPAddress}
	$Report | Add-Member -Type NoteProperty -Name LastLogonDate -Value $_.LastLogonDate
	$Report | Add-Member -Type NoteProperty -Name CreationDate -Value $_.WhenCreated
	If (($Object.psbase.invokeget(“TerminalServicesProfilePath“))) {$Report | Add-Member -Type NoteProperty -Name "Desktop User" -Value "True"}
	ElseIf (!($Object.psbase.invokeget(“TerminalServicesProfilePath“))) {$Report | Add-Member -Type NoteProperty -Name "Desktop User" -Value "False"}
	$FullReport+=$Report
}
$FullReport | Export-CSV $OutFile".csv"
}
}