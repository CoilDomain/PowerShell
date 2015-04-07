$Users=Get-Mailbox | Where-Object {$_.DistinguishedName -like "*OUNAME*"}

Function New-PSTExportJob ($UserName){ 
$FullPath="\\FileServer\MailExport\"+$UserName+".pst"
New-MailboxExportRequest -Mailbox $UserName -FilePath $FullPath -Suspend
}

Foreach ($User in $Users) {
New-PSTExportJob -Username $User.samaccountName 
}

Function Start-ExportJobs ($Rate) {
Get-MailboxExportRequest
If (!(Get-MailboxExportRequest -Status InProgress)) { 
Get-MailboxExportRequest | Where-Object {$_.Status -match "Suspended"} | Select -First $Rate | Resume-MailboxExportRequest
Sleep 30
Start-ExportJobs -Rate $Rate
}
ElseIf ((Get-MailboxExportRequest -Status InProgress)) { 
Sleep 30
Start-ExportJobs -Rate $Rate
}
}

Start-ExportJobs -Rate 2