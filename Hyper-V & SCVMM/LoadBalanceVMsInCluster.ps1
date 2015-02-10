# Filename:      LoadBalanceVMsInCluster.ps1
# Description:   Load balances virtual machines in a cluster by
#                calculating the amount of memory on the hosts with
#                the memory used by the virtual machines to
#                determine whether the virtual machines should be 
#                migrated.

# Get the Virtual Machine Manager server.
Get-VMMServer -computername "VMMServer01.Contoso.com" | out-null

# Get the cluster.
$Cluster = Get-VMHostCluster -name "Cluster01.Contoso.com"

# Create an array to store the names of the virtual machines 
# that cannot be migrated. 
$FailedVMs = @()

# Create a loop to repeat the process.
Do
{
   # Get the Hosts in the cluster, and then get the host with
   # the most amount of available memory and the host with the 
   # least amount of available memory.

   $vmhosts = @(Get-VMhost -VMHostCluster $cluster | sort-object -property availablememory -descending)
   $h=0
   $HostMostMem = $vmhosts[$h]
   $count = $vmhosts.count -1
   $HostLeastMem = $vmhosts[$count]

   # Get the virtual machines on the host with the least available memory.
   $VMs = @(Get-VM -vmhost $HostLeastMem | 
        Where-Object {$FailedVMs -notContains $_.Name }  |
        Sort-Object -property memory -descending)
    If (! $Vms) { break }

   $i=0
   $VM = $VMs[$i]

   # Create a function to calculate whether the amount of memory on the
   # host with the least amount of available memory plus the memory used
   # by the specified virtual machine is less than the memory on thehost 
   # with the most amount of available memory plus the memory used by the 
   # specified virtual machine.

   Function CalculateMemory ($Host1, $Host2, $VirtualMachine)
   {
      $MemoryCalc = ($HostLeastMem.availablememory+$VM.memory) -lt ($HostMostMem.availablememory-$VM.memory)
      $MemoryCalc
   }

   # Call the function to do the initial memory calculation.
   $MemoryCalc = CalculateMemory $HostMostMem $HostLeastMem $VM

   # Create a loop that recalculates the memory for each virtual machine
   # in the array while the memory calculation does not equal True.

   While ($MemoryCalc -ne $True)
   {
      If ($i -lt ($VMs.count-1))
      {
         $i = $i+1
         $VM = $VMs[$i]
         $MemoryCalc = CalculateMemory $HostMostMem $HostLeastMem $VM
      }
      Else 
      {
         Write-Host "The virtual machines are load balanced in the cluster."
         If ($FailedVMs) {Write-Host "The following virtual machines were not able to be migrated:" $FailedVMs}
         Break
      }
   }

   # If the memory calculation equals True, migrate the specified virtual
   # machine to the host with the most amount of available memory.

   If ($MemoryCalc -eq $True)
   {
      # Get the host rating for $HostMostMem to ensure that the migration will succeed.
      $HostRating = Get-VMHostRating -VM $VM -VMHost $HostMostMem -PlacementGoal "LoadBalance" -IsMigration

      # If the host rating for $HostMostMem is greater than or equal to 3, migrate the virtual machine.
      If ($HostRating.Rating -ge "3")
      {
         Write-Host "Migrating virtual Machine $VM from host $HostLeastMem to host $HostMostMem."

      # If the virtual machine cannot be migrated, display the error, add the virtual machine to the
      # $FailedMVs array, and then continue.
$err = @()
Move-VM -VM $VM -VMHost $HostMostMem -ErrorAction SilentlyContinue -ErrorVariable err| out-null
         If ($err) 
         {
            $err | Write-Error
            $FailedVMs += $vm.Name
         }

      }

      # If the host rating for $HostMostMem is zero, find the next host with the most available memory.
      ElseIf ($HostRating.Rating -eq "0")
      {
         $h = $h+1
         $HostMostMem = $vmhosts[$h]

         If ($HostMostMem = $HostLeastMem) 
         {
            Write-Host "There are no other hosts to which virtual machine $VM can be migrated."
            Return
         }

         $HostRating = Get-VMHostRating -VM $VM -VMHost $HostMostMem -PlacementGoal "LoadBalance" -IsMigration

         # If the host rating for $HostMostMem is greater than or equal to three, migrate the
         # virtual machine.
         If ($HostRating.Rating -ge "3")
         {
            Write-Host "Migrating virtual Machine $VM from host $HostLeastMem to host $HostMostMem."
            Move-VM -VM $VM -VMHost $HostMostMem | out-null
         }
         Else
         {
            Write-Host "There is no host with a high enough placement rating to load balance the virtual machines."
            Return
         }
      }

      Else
      {
         Write-Host "There is no host with a high enough placement rating to load balance the virtual machines."
         Return
      }
   }

   Else
   {
      Return
   }
}While ($MemoryCalc -eq $True)
# Loop to repeat the process until the cluster is load balanced.

