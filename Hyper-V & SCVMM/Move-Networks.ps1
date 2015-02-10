Function Move-Networks  ($VM, $Network)	{
        $Adapters = Get-VM $VM | Get-NetworkAdapter | Where-Object {$_.NetworkName -ne "$Network"}
		ForEach ($Adapter in $Adapters)	{
			Set-NetworkAdapter -NetworkAdapter $Adapter -NetworkName $Network
						}
        				}
