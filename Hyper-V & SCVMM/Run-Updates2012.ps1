((Get-SCComplianceStatus).BaselineLevelComplianceStatus[1].UpdateLevelComplianceStatus | Where-Object {$_.ComplianceState -match "NonCompliant"}).update.name

Get-SCUpdateServer | Start-SCUpdateServerSynchronization

$addedUpdateList = @()
Get-SCUpdate | Where-Object {$_.IsApproved -match "False"} | Foreach { 
$addedUpdateList += Get-SCUpdate -ID $_.ID
}
Get-SCBaseline | Set-SCBaseline -AddUpdates $addedUpdateList

Get-SCVMMManagedComputer | Start-SCComplianceScan

$managedComputer = Get-SCVMMManagedComputer -ComputerName "vmm01-tpa02.cl.hostwaycloud.com"
$baseline = Get-SCBaseline -Name "Windows Updates"
Start-SCUpdateRemediation -VMMManagedComputer $managedComputer -Baseline $baseline -SuspendReboot -RunAsynchronously

$managedComputer = Get-SCVMMManagedComputer -ComputerName "vmm02-tpa02.cl.hostwaycloud.com"
$baseline = Get-SCBaseline -Name "Windows Updates"
Start-SCUpdateRemediation -VMMManagedComputer $managedComputer -Baseline $baseline -SuspendReboot -RunAsynchronously
