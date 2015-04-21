Function Get-MailboxReport ($UserFile, $ReportFile) {
$Users=Get-Content $UserFile
$Report=New-Object System.Object
$FullReport=@()
Foreach ($User in $Users) {
$Report=New-Object System.Object
$UserName=$User
$EmailAddress=(Get-Mailbox -Identity $User).PrimarySMTPAddress
$MailboxSize=(Get-Mailbox -Identity $User | Get-MailboxStatistics).TotalItemSize.Value
$Report | Add-Member -Type NoteProperty -Name UserName -Value $UserName
$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $EmailAddress
$Report | Add-Member -Type NoteProperty -Name "Mailbox Size" -value $MailBoxSize
$FullReport+=$Report
}
$FullReport | Sort-Object -Property "Mailbox Size" -Descending
}