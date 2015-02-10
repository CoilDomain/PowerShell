Function Failover-VM    ($VMName)    {
        $VM = Get-VM TestVM
        $HVR = $VM | Get-VMReplication -Computername $VM.Hostname
                If ($HVR.Mode -match "Primary")      {
		$HVRHost = Get-VMReplication -Computername $HVR.PrimaryServer
                $Cert = Get-VMReplicationServer $HVR.CurrentReplicaServerName
                Start-VMFailover $VM -Prepare -Computername $HVRHost.PrimaryServer  -Confirm:$false
                Start-VMFailover $VM -ComputerName $HVRHost.CurrentReplicaServerName  -Confirm:$false
                Set-VMReplication $VM -Reverse -ComputerName $HVRHost.CurrentReplicaServerName -Confirm:$false -CertificateThumbprint $Cert.certificatethumbprint -CompressionEnabled $true
                                                        }
                ElseIf ($HVR.Mode -match "Replica")  {
		$HVRHost = Get-VMReplication -Computername $HVR.CurrentReplicaServerName
                $Cert = Get-VMReplicationServer $HVR.CurrentReplicaServerName
                Start-VMFailover $VM -Prepare -Computername $HVRHost.PrimaryServer  -Confirm:$false
                Start-VMFailover $VM -ComputerName $HVRHost.CurrentReplicaServerName  -Confirm:$false
                Set-VMReplication $VM -Reverse -ComputerName $HVRHost.CurrentReplicaServerName -Confirm:$false -CertificateThumbprint $Cert.certificatethumbprint -CompressionEnabled $true
                                                        }
}
