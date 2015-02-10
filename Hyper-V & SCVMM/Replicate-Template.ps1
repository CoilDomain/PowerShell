Function Replicate-Template ($Source, $Destination)     {
$Templates=Get-SCVMTemplate -VMMServer $Source | Where-Object {$_.name -notlike "Temp*"}
$Directory=$pwd

Foreach ($Template in $Templates)       {
	#Checks if template exists on destination
        If (!(Get-SCVMTemplate -VMMServer $Destination -Name $Template.Name))   {
                $SourceVHDPath=Get-SCVMTemplate -VMMServer $Source -Name $Template.Name | Get-SCVirtualHardDisk
        #If the template has a VHD, it will proceed.
        If (($SourceVHDPath))   {
		#This collects the library servers and replaces the name of the source with the destination library server
                [string]$SourceLib=($SourceVHDPath.LibraryServer).Name
                [string]$DestinationLib=(Get-VMMServer $Destination | Get-SCLibraryServer).Name
                $DestinationVHDFile=$SourceVHDPath.Location.Replace($SourceLib, $DestinationLib)
                $DestinationVHDFolder=$SourceVHDPath.Directory.Replace($SourceLib, $DestinationLib)

		#This creates a folder on the destination then uses BITS to transfer the file over.
                New-Item -ItemType directory -Path $DestinationVHDFolder
                Start-BitsTransfer -Source $SourceVHDPath.Location -Destination $DestinationVHDFile | Complete-BitsTransfer

		#This validates that the VHD exists on the destination, then exports the template from the source and imports it to the destination
                If ((Test-Path $DestinationVHDFile))    {
                        Export-SCTemplate -VMMServer $Source -Path $Directory -VMTemplate $Template -Overwrite -SettingsIncludePrivate
                        $XMLPath=ls $Directory | Where-Object {$_.Name -like "$Template*"}
                        $package = Get-SCTemplatePackage -Path $XMLPath.FullName
                        $allMappings = New-SCPackageMapping -TemplatePackage $package
                        Import-SCTemplate -VMMServer $Destination -TemplatePackage $package -Name $Template.Name -PackageMapping $allMappings -SettingsIncludePrivate

                        Get-LibraryShare -VMMServer $Destination | Refresh-LibraryShare
                        $VHD=Get-SCVirtualHardDisk -VMMServer $Destination | Where-Object {$_.SharePath -like $DestinationVHDFile}

                If (($VHD))     {
			#Validates that the VHD is indeed there, if so it attaches it to the template.
                        Get-SCVMTemplate -VMMServer $Destination -Name $Template.Name | New-SCVirtualDiskDrive -VirtualHardDisk $VHD -IDE -Bus 0 -LUN 0 -VolumeType BootAndSystem -CreateDiffDisk $false
                                }
                ElseIf (!($VHD))        {
			#If the VHD is not there, it removes the template from the destination to prevent any issues.
                        Get-SCVMTemplate -VMMServer $Destination -Name $Template.Name | Remove-SCVMTemplate
                                        }
                                                        }
                                }
                                                                                }
                                        }
}

