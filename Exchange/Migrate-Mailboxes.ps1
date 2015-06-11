Get-MoveRequest | Where-Object {$_.Status -match "Completed"} | Remove-MoveRequest -Confirm:$false
$Users=Get-Mailbox | Where-Object {$_.OrganizationalUnit -notlike "*Disabled*"} | Where-Object {$_.ServerName -notlike "ahcex2010db*"} | Where-Object {$_.Database -notlike "SSD Mailbox Database*"} | Where-Object {$_.MailboxMoveTargetMDB -notmatch "SSD Mailbox Database*"} | Where-Object {$_.Name -notmatch "ArchiveMgr_Journal"} | Select -first 8
Foreach ($User in $Users) {
$Database=(Get-MailboxDatabase -Status | Where-Object {$_.Name -like "*SSD*"} | Sort-Object -Property Databasesize)[0].name
New-MoveRequest -Identity $User.SamAccountName -TargetDatabase $Database
}
Function Check-Status {
If ((Get-MoveRequest | Where-Object {$_.Status -match "InProgress"})) {
Get-MoveRequest | Where-Object {$_.Status -match "InProgress"} | Get-MoveRequestStatistics | Sort-Object -Property PercentComplete -Descending
sleep 60
Clear
Check-Status
}
Else{}
}
Check-Status