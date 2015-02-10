Function Replicate-VHD ($VMMServer, $Template) {
	$VMTemplate=Get-SCVMTemplate -VMMServer $VMMServer -Name $Template
	$VMTemplate
	$HardDisk=$VMTemplate | Get-SCVirtualHardDisk
	$SecondaryLibrary=Get-SCLibraryServer -VMMServer $VMMServer | Where-Object {$_.Name -notmatch $HardDisk.LibraryServer}
	$SecondaryPath=$HardDisk.Directory.Replace($HardDisk.LibraryServer.Name, $SecondaryLibrary.Name)
		If (Test-Path $SecondaryPath) {}
		Else	{
			Copy-Item -Recurse -Path $HardDisk.Directory -Destination $SecondaryPath | Out-Null
			Get-LibraryShare | Where-Object {$_.LibraryServer -match $SecondaryLibrary.Name} | Refresh-LibraryShare | Out-Null
			$ReplicatedVHD=Get-SCVirtualHardDisk | Where-Object {$_.Directory -like $SecondaryPath}
		If (($ReplicatedVHD)) {
			$ReplicatedVHD | Set-SCVirtualHardDisk -Release $VMTemplate.Name -FamilyName $VMTemplate.Name | Out-Null
			$HardDisk | Set-SCVirtualHardDisk -Release $VMTemplate.Name -FamilyName $VMTemplate.Name | Out-Null
					}
			}
}

