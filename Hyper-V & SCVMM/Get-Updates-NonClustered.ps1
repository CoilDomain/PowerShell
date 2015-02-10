Add-PSSnapin Microsoft.SystemCenter.VirtualMachineManager

Add-PSSnapin Microsoft.EnterpriseManagement.OperationsManager.Client

$VMMServer = Get-VMMServer 10.140.136.130

$VMHosts = Get-VMHost -VMMServer $VMMServer | Where-Object {$_.name -ge "msh34.domani.tld.hostway"} | Sort-Object Name

function StartMaintenance	{
        Disable-VMHost $VMHost | Out-Null
							}

function EndMaintenance	{
		Write-Host "Placing host $VMHost back into service."
		Enable-VMHost $VMHost | Out-Null
						}

function CheckForReboot {
$baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine",$VMhost)
$key = $baseKey.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
$subkeys = $key.GetSubKeyNames()
$key.Close()
$baseKey.Close()
		If ($subkeys | Where {$_ -eq "RebootPending"})	{
		Write-Host "Reboot is required: Restarting $VMHost"
		Restart-Computer -ComputerName $VMHost -Force
		sleep 120
														}
		Else    {
		Write-Host "No Reboot required."
				}
                        }

function CheckVMStatus  {
$VMStatus = Get-VM -VMMServer $VMMServer -VMHost $VMHost | Select Status
		if ($VMStatus -match "HostNotResponding")       {
		Write-Host "SCVMM has not updated the status of the Virtual Machines yet"
		sleep 120
		CheckVMStatus
														}
		Else    {
		Write-Host "Powering on Virtual Machines"
		Get-VM -VMMServer $VMMServer -VMHost $VMHost | Start-VM | Out-Null
				}
                        }

function CheckHostStatus	{
$Status = Get-Service -Computername $VMHost VMMS -erroraction silentlycontinue | select status
		if ($Status -match "Running")   {
		Write-Host "Host is Up"
										}
		Else    {
		Write-Host "Host is still rebooting"
		sleep 120
		CheckHostStatus
				}
							}

function CheckWUInstall {
$WUInstallStatus = Get-Content "$pwd\$VMHost.log" | Select-Object -Last 1
If ($WUInstallStatus -match "No Updates are available, nothing to do!") {Write-Host "No Updates are available, nothing to do!"} 
else {InstallUpdates}
} 

function InstallUpdates {
                psexec.exe \\$VMHost -s -c \\domani.tld.hostway\NETLOGON\wuinstall.exe /install /accepteula > "$pwd\$VMHost.log"
                CheckForReboot
                CheckHostStatus
                CheckWUInstall
                        }  

Foreach ($VMHost in $VMHosts)   {
		StartMaintenance
		InstallUpdates
		CheckWUInstall
		CheckVMStatus
		EndMaintenance
                                }
