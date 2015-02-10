Function Set-Replica ($VMName, $Broker) {
    $VM = Get-VM $VMName
    $Cert = Get-VMReplicationServer -ComputerName $VM.Hostname

    Enable-VMReplication -CertificateThumbprint $Cert.CertificateThumbprint -CompressionEnabled:$True -ReplicaServerName $Broker -VMName $VMName -ReplicaServerPort 443 -AuthenticationType Certificate -computername $VM.Hostname -AutoResynchronizeEnabled:$true
    Start-VMInitialReplication -ComputerName $VM.Hostname -VMName $VMName
}
