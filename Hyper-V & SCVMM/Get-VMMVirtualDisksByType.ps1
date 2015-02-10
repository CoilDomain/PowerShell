<#
Overview
The script connects to a VMM Server and gets list of all of the VMs.

Then enumerates all of the disks, and snapshots for the VM and outputs them in a CSV file.

NOTE: The script is still not final. I'm currently performing some verification tests.

Input
[String]VMMServer - the name or FQDN of the VMM Server

[String]OutputFile - The output file where the information has to be written

Output
A file containing information about the VMs, Disks, Size etc. in CSV format
#>

[cmdletBinding()]
Param(
[Parameter(Mandatory=$true,Position=1)]
[String]$VMMServer,

[Parameter(Mandatory=$true,Position=2)]
[String]$OutputFile
)

# Check if the VMM Snapin is already loaded and if not - load it
if ( (Get-PSSnapin -Name Microsoft.SystemCenter.VirtualMachineManager -ErrorAction SilentlyContinue ) -eq $null) 
{ 
    Add-PSSnapin Microsoft.SystemCenter.VirtualMachineManager
}

# Connect to the VMM Server
Write-Output ("Connecting to VMM Server: {0}" -f $VMMServer)
Get-VMMServer $VMMServer | Out-Null

# Get a list of all the VMs. You can change the filter here to narrow the VM scope
# For example you can use -Name "carls*" to get only 1 VM which has 3 snapshots or "beta*" for all beta-RND VMs.
$VMs = Get-VM -Name "*"

# Create an empty container for the VirtualDisks
$AllVirtualDisks = @()

# Get the number of VMs (to be used for status counter)
$TotalVMs = $VMs.Count
$currentVM = 0
# Get the Disks for all of the Virtual Machines and store them in the $AllVirtualDisks container
ForEach ($VM in $VMs)
{
    # Status Tracking in %
    $currentVM++
    $percentsCompleted = ("{0:N0}" -f ($currentVM/$TotalVMs*100))
    Write-Output ("[{0}%] Enumerating disks for {1}" -f $percentsCompleted,$VM.Name)
    $DisksPerVM = $VM | Get-VirtualHardDisk | select VMHost,VHDtype,@{n="DiskName";e={$_.name}},@{n="CurrentSizeGB";e={ "{0:N2}" -f ($_.size/1GB)}},@{n="MaxSizeGB";e={"{0:N2}" -f ($_.MaximumSize/1GB)}},Directory,Location,AddedTime
    
    #Create a variable that'll store the total VHD Space used by the VM and set it to 0
    $perVMTotalSpace = 0
        
    ForEach ($SingleDisk in $DisksPerVM)
    {
        
        # Set the variable for the default storage type to VHD
        $StorageType = "VHD"
        
        # Add property to the object containing the VM name
        $singleDisk | Add-Member -Membertype NoteProperty -Name "VirtualMachineName" -Value $VM
        
        #Add Property to hold the Total Storage used by VM (Only 1 field will be filled per VM)
        $singleDisk | Add-Member -MemberType NoteProperty -Name "TotalVMStorage" -Value ""
        
        # Check if the VHD is a snapshot, if so list the containing directory's filesystem and find the master disk and any other snapshots
        if ($singleDisk.Location -like "*.avhd")
        {
            # Get the disk's location as UNC path 
            $HostServerUNC = ("\\{0}\{1}`$" -f $VM.VMHost,$singleDisk.Location.substring(0,1))
            $locationUNC = $singleDisk.Directory -replace $singleDisk.Directory.substring(0,2),$HostServerUNC
            $filesystemDisks = Get-ChildItem -path $locationUNC -filter "*vhd"
            
            #Create a new entry for each of the files
            ForEach ($fsDisk in $FileSystemDisks)
            {
                #Create a custom object to hold the information for the disk and add the same properties as the root object ($singleDisk)
                $tempSingleDisk = New-Object PSObject
                $singleDisk.PSObject.Properties | ForEach { $tempSingleDisk | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value }
                
                
                $tempSingleDisk.CurrentSizeGB = "{0:N2}" -f ($fsDisk.Length/1GB)
                $tempSingleDisk.DiskName = $fsDisk.Name
                
                #Check if it's a Snapshot and change the storagetype to Snapshot
                if ($fsDisk.Name -like "*.avhd") { $StorageType = "Checkpoint" } else { $storageType = "VHD" }
                
                $tempSingleDisk | Add-Member -MemberType NoteProperty -Name "StorageType" -Force -Value $StorageType
                
                $perVMTotalSpace += $tempSingleDisk.CurrentSizeGB # add the size of this disk to the total amount of space used by VM
                
                #Add the current disk to the array
                $AllVirtualDisks += $tempSingleDisk
            }
            
        }
        else
        {
            # Check if the disk is HBS
            if ($singleDisk.Location -like "*HBS*")
            {
                $StorageType = "HBS"
            }

            $singleDisk | Add-Member -MemberType NoteProperty -Name "StorageType" -Value $StorageType
            
            $perVMTotalSpace += $singleDisk.CurrentSizeGB #Add the size of this disk to the total amount of space used by VM
            
            # Add the current disk to the array
            $AllVirtualDisks += $SingleDisk
        }
    }
    
    #Add one more record containing only the Total storage used by the VM
    $objVMTotalSpace = New-Object PSObject
    $objVMTotalSpace | Add-Member -MemberType NoteProperty -Name "VirtualMachineName" -Value $VM
    $objVMTotalSpace | Add-Member -MemberType NoteProperty -Name "TotalVMStorage" -Value $perVMTotalSpace
    $objVMTotalSpace | Add-Member -MemberType NoteProperty -Name "StorageType" -Value "Total"
    $AllVirtualDisks += $objVMTotalSpace
}

#Create the output file and write all the information in it
Write-Output ("`nWriting output file {0}" -f $OutputFile)
$AllVirtualDisks | select VirtualMachineName, DiskName, StorageType, CurrentSizeGB, MaxSizeGB, TotalVMStorage, VHDtype, Location, Directory, AddedTime |  ConvertTo-Csv | out-file $OutputFile
#$AllVirtualDisks | select VirtualMachineName, DiskName, StorageType, CurrentSizeGB, MaxSizeGB, TotalVMStorage, VHDtype, Location, Directory, AddedTime | Format-Table