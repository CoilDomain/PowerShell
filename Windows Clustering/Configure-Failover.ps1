Function Configure-Failover	($ClusterName, $ClusterIP, $NodeName)	{
If ((Get-WindowsFeature Failover-Clustering).Installed -match "False")	{
	Install-WindowsFeature Failover-Clustering
	Install-WindowsFeature RSAT-Clustering-PowerShell
																		}
Import-Module FailoverClusters

	If (!(Get-Cluster -Name $ClusterName))	{
		New-Cluster -Name $ClusterName -StaticAddress $ClusterIP
											}
												
	If (!(Get-ClusterNode))	{
		Add-ClusterNode -Cluster $ClusterName
							}
							
	If ((Get-ClusterAvailableDisk))	{
		Get-ClusterAvailableDisk | Add-ClusterDisk | Add-ClusterSharedVolume		
									}
																	}