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
			Else {Write-Host "Disks are already formatted"}
                                                        }
                                        }
                                                                        }
