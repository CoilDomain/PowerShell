Function Configure-iSCSI ($ChapUser, $ChapSecret, $Target, $MultiPath)  {
        If (!(Get-iSCSIConnection))     {
                New-IscsiTargetPortal -TargetPortalAddress $Target
                Get-IscsiTarget | Connect-IscsiTarget –AuthenticationType ONEWAYCHAP -ChapUsername $ChapUser -ChapSecret $ChapSecret
		sleep 1
                $Disks = Get-IscsiConnection | Get-Disk
                        Foreach ($Disk in $Disks)       {
                        If ($Disks.PartitionStyle -match "RAW") {
                        $Disk | Initialize-Disk 
			$Format = $Disk | New-Partition -UseMaximumSize 
			sleep 5
			$Format | Format-Volume -Confirm:$false
                                                                }
			Else {Write-Host "Something wrong happened"}
                                                        }
                                        }
	Else 	{
		Get-IscsiTarget
		$Tar = Get-IscsiTarget
		Disconnect-IscsiTarget -NodeAddress $Tar.NodeAddress -Confirm:$false
		Remove-IscsiTargetPortal -TargetPortalAddress 10.140.161.30 -Confirm:$false
		Invoke-Command -ComputerName iSCSI -ScriptBlock {C:\Users\administrator\recreate.ps1}
		}
                                                                        }
Configure-iSCSI -ChapUser ChapUsername -ChapSecret 12101985jason -Target 10.140.161.30
