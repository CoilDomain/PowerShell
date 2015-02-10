Function Make-Template ($Template, $VMMServer, $Library)      {

$Dir = "\\"+$Library+"\Path\"
$FolderPath = $Dir+$Template
$LibraryServer = Get-VMMServer $VMMServer | Get-LibraryServer
$VHDFile = Get-DirectoryChildItem -LibraryServer $LibraryServer -Path "$FolderPath" | Select FileName -First 1
$FullPath = $Dir+$Template+"\"+($VHDFile).FileName
$VMJobGroup = [System.Guid]::NewGuid()

$Verification = Get-Template | Where-Object {$_.Name -eq "$Template"}

If (!$Verification)     {

$CPUType = Get-CPUType -VMMServer $VMMServer | where {$_.Name -eq "3.20 GHz Pentium D (dual core)"}
$VirtualHardDisk = Get-VirtualHardDisk -VMMServer $VMMServer | where {$_.Location -eq $FullPath} | where {$_.HostName -eq "$Library"}
New-VirtualDiskDrive -VMMServer $VMMServer -IDE -Bus 0 -LUN 0 -JobGroup $VMJobGroup -VirtualHardDisk $VirtualHardDisk
$HardwareProfile = Get-HardwareProfile -VMMServer $VMMServer | where {$_.Name -eq "GenericProfile"}

#----Linux----#
If (($Template -like "*CentOS*") -or ($Template -like "*RHEL*") -or ($Template -like "*Ubuntu*"))       {
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -NoCustomization
                                                                                                }
#----Windows 2003 Enterprise 32Bit----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2003*") -and ($Template -like "*ENT*") -and ($Template -like "*x86*"))    {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2003ENT32"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "Windows Server 2003 Enterprise Edition (32-bit x86)"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                                                                        }
#----Windows 2003 Enterprise 64Bit----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2003*") -and ($Template -like "*ENT*") -and ($Template -like "*x64*"))         {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2003ENT64"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "Windows Server 2003 Enterprise x64 Edition"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                                                                        }
#----Windows 2003 Standard 64Bit----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2003*") -and ($Template -like "*STD*") -and ($Template -like "*x64*"))         {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2003STD64"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "WWindows Server 2003 Standard x64 Edition"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                    }
#----Windows 2008 Standard----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2008*") -and ($Template -like "*STD*") -and ($Template -notlike "*SQL*")) {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2008STD"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                    }
#----Windows 2008 Standard with SQL----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2008*") -and ($Template -like "*STD*") -and ($Template -like "*SQL*")) {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2008STDMSSQL"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c osql -U sa -P Hostway501 -S localhost -Q ""sp_grantlogin '%COMPUTERNAME%\administrator'""", "cmd.exe /c osql -U sa -P Hostway501 -S localhost -Q ""sp_addsrvrolemember @loginame='%COMPUTERNAME%\administrator', @rolename='sysadmin'""", "cmd.exe /c osql -U sa -P Hostway501 -S localhost -Q ""sp_password @old='Hostway501', @new='[[NEW_PASSWORD]]', @loginame='sa'""", "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                    }
#----Windows 2012 Standard----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2012*") -and ($Template -like "*STD*") -and ($Template -notlike "*SQL*")) {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2012STD"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "64-bit edition of Windows Server 2012 Standard"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                    }
#----Windows 2012 Standard with SQL----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2012*") -and ($Template -like "*STD*") -and ($Template -like "*SQL*")) {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2012STDMSSQL"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "64-bit edition of Windows Server 2012 Standard"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c osql -U sa -P Hostway501 -S localhost -Q ""sp_grantlogin '%COMPUTERNAME%\administrator'""", "cmd.exe /c osql -U sa -P Hostway501 -S localhost -Q ""sp_addsrvrolemember @loginame='%COMPUTERNAME%\administrator', @rolename='sysadmin'""", "cmd.exe /c osql -U sa -P Hostway501 -S localhost -Q ""sp_password @old='Hostway501', @new='[[NEW_PASSWORD]]', @loginame='sa'""", "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                       }
#----Windows 2008 Web----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2008*") -and ($Template -like "*Web*")) {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2008WEB"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "64-bit edition of Windows Web Server 2008 R2"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                    }
#----Windows 2008 Enterprise----#
ElseIf (($Template -like "*Windows*") -and ($Template -like "*2008*") -and ($Template -like "*ENT*")) {
$GuestOSProfile = Get-GuestOSProfile -VMMServer $VMMServer | where {$_.Name -eq "Windows2008ENT"}
$OperatingSystem = Get-OperatingSystem -VMMServer $VMMServer | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Enterprise"}
New-Template -Name "$Template" -RunAsynchronously  -HardwareProfile $HardwareProfile -JobGroup $VMJobGroup -GuestOSProfile $GuestOSProfile  -ComputerName "*" -FullName "" -OrgName "" -TimeZone 35 -JoinWorkgroup "WORKGROUP" -GuiRunOnceCommands "cmd.exe /c net user root [[NEW_PASSWORD]]", "cmd.exe /c net localgroup Administrators root /add", "cmd.exe /c cscript C:\Scripts\scregedit.wsf /AU 4", "cmd.exe /c cscript C:\Scripts\MicrosoftUpdate.vbs", "cmd.exe /c wuauclt /detectnow", "cmd.exe /c C:\Scripts\autoupdate.pl -i" -AnswerFile $null -OperatingSystem $OperatingSystem
                                                    }
                                        }
Else {
Write-Host "There is already a template by this name"
}
        }

