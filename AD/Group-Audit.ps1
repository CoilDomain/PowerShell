$SecurityGroups=Get-ADGroup -Filter * 
$Audit=@()

Foreach ($SecurityGroup in $SecurityGroups) {
$SecurityGroupMembers=(($SecurityGroup | Get-ADGroupMember).Name  | Out-String).Trim()
$AuditList=New-Object PSObject 
$AuditList | Add-Member NoteProperty "Group Name" ($SecurityGroup).Name
$AuditList | Add-Member NoteProperty "Group Members" $SecurityGroupMembers
$AuditList
}