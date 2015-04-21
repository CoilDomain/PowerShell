Function Get-MailboxReport ($Company) {
$FullReport=@()

$Contacts=Get-Contact -OrganizationalUnit $Company
$Contacts | Foreach {
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $_.WindowsEmailAddress
	$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value "Email Contact"
	$FullReport+=$Report	
}

$DistributionGroups=Get-DistributionGroup -OrganizationalUnit $Company
$DistributionGroups | Foreach {
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $_.PrimarySMTPAddress
	$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value "Distribution Group"
	$FullReport+=$Report
}

$Mailboxes=Get-Mailbox -OrganizationalUnit $Company
$Mailboxes | Foreach {
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $_.PrimarySMTPAddress
	$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value ($_ | Get-MailboxStatistics).TotalItemSize.Value
	$FullReport+=$Report
}

$FullReport | Sort-Object -Property "Mailbox Size" -Descending
}