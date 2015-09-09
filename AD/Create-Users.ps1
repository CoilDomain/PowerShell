$accounts=import-csv .\users.csv
$accounts | foreach {
$Username=$_.SamAccountName+"@"+(get-ADDomain).dnsroot
$DisplayName=$_.GivenName+" "+$_.Surname
$Company="Company"
$OU=Get-ADOrganizationalUnit -Filter * | Where-Object {$_.DistinguishedName -like "*$Company*"}
$Description=$Description=$Company+" User"
New-ADuser -Description $Description -UserPrincipalName $username -Name $DisplayName -DisplayName $DisplayName -GivenName $_.GivenName -Surname $_.Surname -PasswordNeverExpires $true -AccountPassword  ($_.Password | ConvertTo-SecureString -AsPlainText -Force) -Enabled $True -Path $OU.DistinguishedName}
