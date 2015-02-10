Get-DPMProtectionGroup | Where-Object {$_.Name -Match "Library Servers"} | Get-DPMDatasource | Get-DPMRecoveryPoint
