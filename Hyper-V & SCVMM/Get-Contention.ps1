Function Get-Contention {
$LP=[math]::Round(((Get-Counter -Counter "\Hyper-V Hypervisor Logical Processor(_Total)\% Total Run Time" -SampleInterval 1 -MaxSamples 5).countersamples.cookedvalue | measure -Average).average)
$VP=[math]::Round(((Get-Counter -Counter "\Hyper-V Hypervisor Virtual Processor(_Total)\% Total Run Time" -SampleInterval 1 -MaxSamples 5).countersamples.cookedvalue | measure -Average).average)
if ($LP -gt $VP){
$LPC=((Get-WmiObject –class Win32_processor).numberofcores | measure -sum).sum
$VPC=((get-vm).processorcount | measure -sum).sum
$PD=$VPC/$LPC
$OAP=($lp/$vp).ToString("P")
Write-Output "The server's CPU resources are at $OAP"
Write-Output "There is a $PD to 1 vCPU to pCPU count"
}
Else{Write-Output "There is no contention"}
}