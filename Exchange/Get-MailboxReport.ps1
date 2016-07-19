Function Get-MailboxReport ($Company) {
$FullReport=@()

$Contacts=Get-Contact -OrganizationalUnit $Company
$Contacts | Foreach {
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $_.WindowsEmailAddress
	$Report | Add-Member -Type NoteProperty -Name "legacyExchangeDN"  -Value  $Null
	$Report | Add-Member -Type NoteProperty -Name "Members" -Value $Null
	$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value "Email Contact"
	$Report | Add-Member -Type NoteProperty -Name "Item Count" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "Deleted Item Count" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "Deleted Item Count (MB)" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "CalendarItems" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "CalendarItems (KB)" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "ContactsItems" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "LastLogonTime" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "LastLoggedOnUserAccount" -value $Null
	$FullReport+=$Report	
}

$DistributionGroups=Get-DistributionGroup -OrganizationalUnit $Company
$DistributionGroups | Foreach {
$Members=$_ | Get-DistributionGroupMember
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value ((Get-adgroup "$_" -Properties *).proxyaddresses | findstr SMTP).replace("SMTP:","")
	$Report | Add-Member -Type NoteProperty -Name "legacyExchangeDN"  -Value $_.LegacyExchangeDN
	$Report | Add-Member -Type NoteProperty -Name "Members" -Value ((0..(($Members | measure).count -1 ) | foreach {($Members)[$_].name}) -join "; ")
	$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value "Distribution Group"
	$Report | Add-Member -Type NoteProperty -Name "Item Count" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "Deleted Item Count" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "Deleted Item Count (MB)" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "CalendarItems" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "CalendarItems (KB)" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "ContactsItems" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "LastLogonTime" -value $Null
	$Report | Add-Member -Type NoteProperty -Name "LastLoggedOnUserAccount" -value $Null
	$FullReport+=$Report
}

$Mailboxes=Get-Mailbox -OrganizationalUnit $Company
$Mailboxes | Foreach {
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value ((Get-adUser -Filter {Name -eq $_} -Properties *).proxyaddresses | findstr SMTP).replace("SMTP:","")
	$Report | Add-Member -Type NoteProperty -Name "legacyExchangeDN"  -Value $_.LegacyExchangeDN
	$Report | Add-Member -Type NoteProperty -Name "Members" -Value $Null
	$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value ($_ | Get-MailboxStatistics).TotalItemSize.Value
	$Report | Add-Member -Type NoteProperty -Name "Item Count" -value ($_ | Get-MailboxStatistics).ItemCount
	$Report | Add-Member -Type NoteProperty -Name "Deleted Item Count" -value ($_ | Get-MailboxStatistics).DeletedItemCount
	$Report | Add-Member -Type NoteProperty -Name "Deleted Item Count (MB)" -value ($_ | Get-MailboxStatistics).TotalDeletedItemSize.Value.ToMB()
	$Report | Add-Member -Type NoteProperty -Name "CalendarItems" -value ($_ | Get-MailboxFolderStatistics | where{$_.Name -eq "Calendar"}).itemsinfolderandsubfolders
	$Report | Add-Member -Type NoteProperty -Name "CalendarItems (KB)" -value ($_ | Get-MailboxFolderStatistics | where{$_.Name -eq "Calendar"}).FolderAndSubfolderSize.ToKB()
	$Report | Add-Member -Type NoteProperty -Name "ContactsItems" -value ($_ | Get-MailboxFolderStatistics | where{$_.Name -eq "Contacts"}).ItemsInFolderAndSubfolders
	$Report | Add-Member -Type NoteProperty -Name "LastLogonTime" -value ($_ | Get-MailboxStatistics).LastLogonTime
	$Report | Add-Member -Type NoteProperty -Name "LastLoggedOnUserAccount" -value ($_ | Get-MailboxStatistics).LastLoggedOnUserAccount
	$FullReport+=$Report
}

$FullReport | Sort-Object -Property "Mailbox Size" -Descending
}
Get-MailboxReport -Company "Users Auditz" | Export-CSV ./Auditz.csv
Notepad ./Auditz.csv