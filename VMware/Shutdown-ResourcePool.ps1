function Shutdown-ResourcePool ($ResourcePool)	{
	$VMs = Get-VM | Where-Object {(Get-ResourcePool -VM $_) -match $ResourcePool -and $_.PowerState -match "PoweredOn"}
	ForEach ($VM in $VMs)	{
	Get-VM $VM | Shutdown-VMGuest -Confirm:$false | Out-Null
	Write-Output "Shutting down $VM"
				}
						}
