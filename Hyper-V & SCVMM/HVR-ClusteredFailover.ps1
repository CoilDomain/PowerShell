Function Failover-VM    ($VMName)    {
        $VM = Get-VM $VMName
        $ReplicaInfo = $VM | Get-VMReplication -Computername $VM.Hostname
                If ($ReplicaInfo -match "Primary")      {
		$CertificateThumbPrint = Get-VMReplicationServer $ReplicaInfo.CurrentReplicaServerName
                $VM | Stop-VM
                Start-VMFailover -VMName $VM -Prepare -Computername $ReplicaInfo.PrimaryServer -Confirm:$false
                Start-VMFailover -VMName $VM -ComputerName $ReplicaInfo.CurrentReplicaServerName -Confirm:$false
                Set-VMReplication $VM -Reverse -ComputerName $ReplicaInfo.CurrentReplicaServerName -Confirm:$false -CertificateThumbprint $Cert.certificatethumbprint
                                                        }
                ElseIf ($ReplicaInfo -match "Replica")  {
		$CertificateThumbPrint = Get-VMReplicationServer $ReplicaInfo.PrimaryServer
                Get-VM $VMName -Computername $ReplicaInfo.PrimaryServer | Stop-VM
                Start-VMFailover -VMName $VM -Prepare -Computername $ReplicaInfo.PrimaryServer -Confirm:$false
                Start-VMFailover -VMName $VM -ComputerName $ReplicaInfo.ReplicaServer -Confirm:$false
                Set-VMReplication $VMName -Reverse -ComputerName $ReplicaInfo.ReplicaServer -Confirm:$false -CertificateThumbprint $Cert.certificatethumbprint
                                                        }
}
