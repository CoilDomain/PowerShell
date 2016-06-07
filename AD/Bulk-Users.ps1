If (!(Get-Module | Where-Object {$_.Name -match "activedirectory"})){import-module activedirectory}
If (!(Get-Module | Where-Object {$_.Name -like "*.domain.com"})){. 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto}
$ErrorActionPreference="SilentlyContinue"

$accounts=import-csv .\users.csv
$accounts | foreach {
$DisplayName=$_.FirstName+" "+$_.LastName
$Company=$_.Company
$OU=Get-ADOrganizationalUnit -Filter * | Where-Object {$_.DistinguishedName -like "*$Company*"}
$Description=$Description=$Company+" User"

If (!($_.Username)) {
$SamAccountName=$_.FirstName[0]+$_.LastName
}
ElseIf (($_.Username)) {
$SamAccountName=$_.Username
}

$ValidateUser=Get-ADUser $SamAccountName -ErrorAction SilentlyContinue

If (!($ValidateUser)) {
$Username=$SamAccountName+"@"+(get-ADDomain).dnsroot
New-ADuser -SamAccountName $SamAccountName -Description $Description -UserPrincipalName $username -Name $DisplayName -DisplayName $DisplayName -GivenName $_.FirstName -Surname $_.LastName -PasswordNeverExpires $true -AccountPassword  ($_.Password | ConvertTo-SecureString -AsPlainText -Force) -Enabled $True -Path $OU.DistinguishedName
}
ElseIf (($ValidateUser)) {
$ExistingUser=(Get-ADUser $SamAccountName | select samaccountname | sort -descending)[0].SamAccountName
$IntergerCheck=$ExistingUser.Substring($ExistingUser.length-1)
$IntergerValue=[bool]($IntergerCheck -as [double])
If ($IntergerValue -match "True") {
$NewInterger=[Int]$ExistingUser.Substring($ExistingUser.length-1) + [Int]1
$NewUserName=$ExistingUser.Replace($ExistingUser.Substring($ExistingUser.length-1), $NewInterger)
$SamAccountName=$NewUserName
$Username=$NewUserName+"@"+(get-ADDomain).dnsroot
}
ElseIf ($IntergerValue -match "False") {
$ExistingUser=(Get-ADUser $SamAccountName | select samaccountname | sort -descending)[0].SamAccountName
$NewUserName=$ExistingUser+1
$Username=$NewUserName+"@"+(get-ADDomain).dnsroot
$SamAccountName=$NewUserName
}
}
New-ADuser -SamAccountName $SamAccountName -Description $Description -UserPrincipalName $username -Name $DisplayName -DisplayName $DisplayName -GivenName $_.FirstName -Surname $_.LastName -PasswordNeverExpires $true -AccountPassword  ($_.Password | ConvertTo-SecureString -AsPlainText -Force) -Enabled $True -Path $OU.DistinguishedName

If (($_.EmailAddress)) {
$Database=Get-MailboxDatabase $_.Database
Enable-Mailbox -Alias $SamAccountName -Database $Database -PrimarySMTPAddress $_.EmailAddress -Identity $SamAccountName
}
}
