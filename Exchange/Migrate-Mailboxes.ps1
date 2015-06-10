Get-MoveRequest | Where-Object {$_.Status -match "Completed"} | Remove-MoveRequest
$Users=Get-Mailbox | Where-Object {$_.OrganizationalUnit -notlike "*Disabled*"} | Where-Object {$_.ServerName -notlike "ahcex2010db*"} | Where-Object {$_.Database -notlike "SSD Mailbox Database*"} | Where-Object {$_.MailboxMoveTargetMDB -notmatch "SSD Mailbox Database*"} | Where-Object {$_.Name -notmatch "ArchiveMgr_Journal"} | Select -first 20
Foreach ($User in $Users) {
New-MoveRequest -Identity $User.SamAccountName -TargetDatabase "SSD Mailbox Database 2"
}
Function Check-Status {
If ((Get-MoveRequest | Where-Object {$_.Status -match "InProgress"})) {
Get-MoveRequest | Where-Object {$_.Status -match "InProgress"} | Get-MoveRequestStatistics | Sort-Object -Property PercentComplete -Descending
sleep 60
Check-Status
}
Else{}
}
Check-Status