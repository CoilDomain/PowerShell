Function LoadBalance-Storage    {
        Function Get-CSVFreeSpace       {

                $objs = @()
                $csvs = Get-ClusterSharedVolume -Cluster "MSCL01"
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
                $obj
                }
                }
                                        }
$VMs = get-vm | Where-Object {$_.Status -match "PowerOff"}
        Foreach ($VM in $VMs)   {
                Get-VM $VM | Select Name,Status,location
                Sleep 10
                $FreeCSV = Get-CSVFreeSpace | Sort-Object -Property PercentFree -Descending | Select-Object -First 1
                If ($VM.Location.Trim("$VM.Name") -ne $FreeCSV.Path+"\")        {
                Move-VM -VM $VM -Path $FreeCSV.Path -UseLAN -VMHost $VM.HostName
                                                                                }
                                }
                                }
