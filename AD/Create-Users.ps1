$accounts=import-csv .\users.csv
$accounts | foreach {
$Username=$_.SamAccountName+"@"+(get-ADDomain).dnsroot
$DisplayName=$_.GivenName+" "+$_.Surname
New-ADuser -UserPrincipalName $username -Name $DisplayName -DisplayName $DisplayName -GivenName $_.GivenName -Surname $_.Surname -PasswordNeverExpires $true -AccountPassword  ("Password123" | ConvertTo-SecureString -AsPlainText -Force) -EmailAddress $_.emailaddress -Enabled $True}
