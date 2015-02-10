function Set-VMHostMaintenance ($VMHost)        {

$MaintenanceStatus = Get-VMHost -VMMServer $VMMServer $VMHost | Select OverallState
$VMMServer = Get-VMMServer "10.0.0.1"
$SCOMServer = "scom"

                New-PSDrive -Name:Monitoring -PSProvider:OperationsManagerMonitoring -Root:\ | Out-Null
                New-ManagementGroupConnection -ConnectionString:$SCOMServer | Out-Null
                Set-Location "Monitoring:\$SCOMServer"

function StartMaintenance       {
$SCOMAgent = Get-Agent | Where-object {$_.Name -match $VMHostù}
                Write-Host "Setting $VMHost to unavailable for placement"
                Set-VMHost -VMHost $VMHost -AvailableForPlacement $FALSE | Out-Null
                Write-Host "Placing host $VMHost into maintenance mode."
                $SCOMAgent.HostComputer | New-MaintenanceWindow -StartTime (Get-Date) -EndTime ([DateTime]::Now).AddMinutes(60) -Comment "Weekly reboot"
                Disable-VMHost $VMHost -MoveWithinCluster | Out-Null
$Maintenance = Get-VMHost -VMMServer $VMMServer $VMHost | Select OverallState
                if ($Maintenance -match "MaintenanceMode")      {
                Write-Host "Host is in Maintenance Mode"
                }
                Else {
                        Write-Host "Host did not successfully go into Maintenance Mode, retrying"
                        StartMaintenance
                }
                                                        }

function EndMaintenance {
$SCOMAgent = Get-Agent | Where-object {$_.Name -match $VMHostù}
                Write-Host "Placing host $VMHost back into service."
                Enable-VMHost $VMHost | Out-Null
                Set-VMHost -VMHost $VMHost -AvailableForPlacement $TRUE | Out-Null
                $SCOMAgent.HostComputer | Set-MaintenanceWindow -EndTime ([DateTime]::Now).AddMinutes(1) -Comment "Finished Windows Updates"
                                                }

function MigrateOfflineVMs  {
$OfflineVMs = Get-VM -VMMServer $VMMServer -VMHost $VMHost | Select Status
$Hosts = Get-VMHost -VMHostGroup "FlexCloud"
                if ($OfflineVMs -match "PowerOff")      {
                Write-Host "There are offline VMs, migrating to another host"
                        $VMs = Get-VM -VMHost $VMHost | Where-Object {$_.Status -eq "PowerOff"}
                        ForEach ($VM in $VMs)   {
                        $HostRatings = Get-VMHostRating -VMHost $Hosts -VM $VM -IsMigration | Sort-Object -descending Rating
                        if ($HostRatings[0].Rating -ne 0)       {
                        $BestHost = Get-VMHost -ComputerName $HostRatings[0].Name
                write-host "Moving $VM to $BestHost"
                Move-VM -VM $VM -VMHost $BestHost | Out-Null
                                                                                                }
                                                                        }
                                                                                        }
                Else    {
                Write-Host "There are no VMs on this server currently."
                                }
                        }    

function CheckHostStatus        {
$HostState = Get-VMHost $VMHost 
                if (($HostState.ComputerState -match "Responding") -and ($HostState.ClusterNodeStatus -match "Running") -and ($HostState.VirtualServerState -match "Running") -and ($HostState.VirtualServerStateString -match "Running") -and ($HostState.CommunicationStateString -match "Responding") -and ($HostState.CommunicationState -match "Responding")) {
                Write-Host "Host is Up"
                                                                                }
                Else    {
                Write-Host "Host is still rebooting"
                sleep 120
                CheckHostStatus
                                }
                                                        }
                if ($MaintenanceStatus -match "MaintenanceMode")      {
                CheckHostStatus
                EndMaintenance
                }
                ElseIf  ($MaintenanceStatus -match "OK") {
                CheckHostStatus
                StartMaintenance
                MigrateOfflineVMs
                }
                }

