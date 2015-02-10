function Get-LargestVMs {
function Get-LargeVMs ($Path) {
	$Size = get-vm -vmmserver 10.140.136.130 | Where-Object {$_.vmcpath -like "*$Path*"} | Select Name,TotalSize,Hostname | Sort-Object TotalSize -Descending | Select-Object -First 5 | Out-String
	Write-Host $Size
}

$objs = @()

$csvs = Get-ClusterSharedVolume -Cluster MSCL01
foreach ( $csv in $csvs )
{
   $csvinfos = $csv | select -Property Name -ExpandProperty SharedVolumeInfo
   foreach ( $csvinfo in $csvinfos )
   {
      $obj = New-Object PSObject -Property @{
         Path        = $csvinfo.FriendlyVolumeName
         PercentFree = $csvinfo.Partition.PercentFree
      }
      $objs += $obj
   }
}

$objs | foreach {
if ($_.PercentFree -ge "70")  {
   Write-Host "################################################"
   Write-Host $_.Path
   Write-Host "Current percent free is"$_.PercentFree
   Write-Host "################################################"
   Get-LargeVMs $_.Path
}
else {
}
}
}
