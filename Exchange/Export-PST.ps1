$Users=Get-Mailbox | Where-Object {($_.DistinguishedName -like "*Disabled Users*") -and ($_.DistinguishedName -notlike "*unofficial*")}

Function New-PSTExportJob ($UserName){ 
$FullPath="\\MailServer\MailExport\"+$UserName+".pst"
New-MailboxExportRequest -Mailbox $UserName -FilePath $FullPath -Suspend
}

Foreach ($User in $Users) {
New-PSTExportJob -Username $User.samaccountName 
}

Function Start-ExportJobs ($Rate) {
Write-Output (Get-MailboxExportRequest -Status completed | measure).count
If (!(Get-MailboxExportRequest -Status InProgress)) { 
Get-MailboxExportRequest | Where-Object {$_.Status -match "Suspended"} | Select -First $Rate | Resume-MailboxExportRequest
Sleep 30
Start-ExportJobs -Rate $Rate
}
ElseIf ((Get-MailboxExportRequest -Status InProgress)) { 
Sleep 30
Start-ExportJobs -Rate $Rate
}
ElseIf (!(Get-MailboxExportRequest -Status InProgress,Queued,Suspended)) {}
}

Start-ExportJobs -Rate 2