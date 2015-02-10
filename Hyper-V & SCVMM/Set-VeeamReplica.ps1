Function Set-FCReplica ($VM, $Source, $Destination) {

If (!(Get-PSSnapin | Where-Object {$_.Name -match "VeeamPSSnapIn"})){Add-PSSnapin -Name VeeamPSSnapIn}

$DestinationPath=(Get-ClusterSharedVolume -Cluster $Destination | ForEach-Object {[PSCustomObject]@{Path = $_.SharedVolumeInfo.FriendlyVolumeName; FreeSpace =$_.SharedVolumeInfo.Partition.FreeSpace}} | Sort-Object -Property Freespace -Descending).Path[0]
$SourceVM=Find-VBRHvEntity -Server $Source -Name $VM 
Add-VBRHvReplicaJob -Name $VM -Path $DestinationPath -Entity $SourceVM -Server $Destination
Get-VBRJob -Name $VM | Enable-VBRJobSchedule
Get-VBRJob -Name $VM | Set-VBRJobSchedule -Periodicaly -FullPeriod 15 -PeriodicallyKind Minutes
}