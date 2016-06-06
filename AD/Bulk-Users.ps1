If (!(Get-Module | Where-Object {$_.Name -match "activedirectory"})){import-module activedirectory}
If (!(Get-Module | Where-Object {$_.Name -like "*.domain.com"})){. 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto}
$ErrorActionPreference="SilentlyContinue"

$accounts=import-csv .\users.csv
$accounts | foreach {
$DisplayName=$_.FirstName+" "+$_.LastName"
$Company="Company"
$OU=Get-ADOrganizationalUnit -Filter * | Where-Object {$_.DistinguishedName -like "*$Company*"}
$Description=$Description=$Company+" User"
$SamAccountName=$_.FirstName[0]+$_.LastName

If ((Get-ADUser $SamAccountName)) {
$ExistingUser=(Get-ADUser $SamAccountName | select samaccountname | sort -descending)[0].SamAccountName
$IntergerCheck=$ExistingUser.Substring($ExistingUser.length-1)
$IntergerValue=[bool]($IntergerCheck -as [double])
If ($IntergerValue -match "True") {
$NewInterger=[Int]$ExistingUser.Substring($ExistingUser.length-1) + [Int]1
$NewUserName=$ExistingUser.Replace($Existing.Substring($ExistingUser.length-1), $NewInterger)
$Username=$NewUserName+"@"+(get-ADDomain).dnsroot
}
ElseIf ($IntergerValue -match "False") {
$ExistingUser=(Get-ADUser $SamAccountName | select samaccountname | sort -descending)[0].SamAccountName
$NewUserName=$ExistingUser+1
$Username=$NewUserName+"@"+(get-ADDomain).dnsroot
}
}

If (!(Get-ADUser $SamAccountName)) {
}

New-ADuser -Description $Description -UserPrincipalName $username -Name $DisplayName -DisplayName $DisplayName -GivenName $_.GivenName -Surname $_.Surname -PasswordNeverExpires $true -AccountPassword  ($_.Password | ConvertTo-SecureString -AsPlainText -Force) -Enabled $True -Path $OU.DistinguishedName

If (($_.EmailAddress)) {
Enable-Mailbox -Alias $SamAccountName -Database $Database -PrimarySMTPAddress $_.EmailAddress
}
