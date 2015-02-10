Function Swap-VHD ($Template, $NewLibrary) {
$VMTemplate=Get-SCVMTemplate -Name $Template
$OldVHD=$VMTemplate | Get-SCVirtualDiskDrive
$NewSharePath=$OldVHD.VirtualHardDisk.SharePath -replace $OldVHD.VirtualHardDisk.LibraryServer.Name.Split(('.')[0])[0], $NewLibrary
$NewVHD=Get-SCVirtualHardDisk | Where-Object {$_.SharePath -like $NewSharePath -and $_.LibraryServer -like "$NewLibrary*"}
$Logging=@{"Template Name"=($VMTemplate.Name);}, @{"Old Path"=($OldVHD.VirtualHardDisk.SharePath);}, @{"New Path"=($NewVHD.Location);}
$Logging | Format-Table -Wrap | Out-File -FilePath ./VMSwap.txt -Append

$VMTemplate | Get-SCVirtualHardDisk | Set-SCVirtualHardDisk -Release $VMTemplate.Name -FamilyName $VMTemplate.Name
Remove-SCVirtualDiskDrive -VirtualDiskDrive $OldVHD
$VMTemplate | New-SCVirtualDiskDrive -VirtualHardDisk $NewVHD -IDE -Bus 0 -LUN 0 -VolumeType BootAndSystem -CreateDiffDisk $false
$VMTemplate | Get-SCVirtualHardDisk | Set-SCVirtualHardDisk -Release $VMTemplate.Name -FamilyName $VMTemplate.Name
}
