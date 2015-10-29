$Users=Get-Content Users.txt


Function New-PSTExportJob ($UserName){ 
$FullPath="\\Server\Share$\"+$UserName+".pst"
New-MailboxExportRequest -Mailbox $UserName -FilePath $FullPath -Suspend -AcceptLargeDataLoss -BadItemLimit unlimited -ContentFilter {Received -gt "10/28/2015 10:50AM"}
}

Foreach ($User in $Users) {
New-PSTExportJob -Username (Get-Mailbox "$User").samaccountName 
}

Function Start-ExportJobs ($Rate) {
Write-Host "Pending:"(Get-MailboxExportRequest -Status Suspended | measure).count "In Progress:" (Get-MailboxExportRequest -Status InProgress | measure).count "Completed:" (Get-MailboxExportRequest -Status Completed | measure).count
If (!(Get-MailboxExportRequest -Status InProgress)) { 
Get-MailboxExportRequest | Where-Object {$_.Status -match "Suspended"} | Select -First $Rate | Resume-MailboxExportRequest
Sleep 30
Start-ExportJobs -Rate $Rate
}
ElseIf ((Get-MailboxExportRequest -Status InProgress)) { 
Sleep 300
Start-ExportJobs -Rate $Rate
}
ElseIf (!(Get-MailboxExportRequest -Status InProgress,Queued,Suspended)) {}
}

Start-ExportJobs -Rate 4