Import-Module BitsTransfer
Function Deploy-SCVMM	{
$Path = "C:\PreReqs"

If (!(Test-Path $Path))	{
mkdir $Path
}

$AUser = "software"
$APass = "support" | ConvertTo-SecureString -asPlainText -Force
$ACreds = New-Object System.Management.Automation.PSCredential($AUser,$APass)

$SCUser = "scvmm-01"
$SCPass = "H0stw@y"
$SCSQLUser = "Administrator"
$SCSQLPass = "H0stw@y"

$Location = "TPA"
$ClusterIP = "10.0.0.90"

Function Create-Cluster	{
Install-WindowsFeature Failover-Clustering, RSAT-Clustering-PowerShell, RSAT-Clustering-Mgmt
If ((Get-WindowsFeature | Where-object {$_.Name -match "Failover-Clustering" -and $_.InstallState -match "Installed"}))	{
	Import-Module FailoverClusters
	        If (!(Get-Cluster -Name SCVMM-$Location))	{
                New-Cluster -Name SCVMM-$Location -StaticAddress $ClusterIP
							}
	        If (!(Get-ClusterNode))	{
        	        Add-ClusterNode -Cluster SCVMM-$Location
					}

	        If ((Get-ClusterAvailableDisk))	{
        	        Get-ClusterAvailableDisk | where-object {$_.Size -eq "1073741824"} | Add-ClusterDisk
			(Get-ClusterResource | Where-Object {$_.ResourceType -match "Physical Disk"}).Name = "Quorum"
			Get-ClusterAvailableDisk | Add-ClusterDisk
			(Get-ClusterResource | Where-Object {$_.Name -notmatch "Quorum" -and $_.ResourceType -match "Physical Disk"}).Name = "SQLServer"
						}
Get-Cluster | Test-Cluster
}
Else	{
	Write-Host "Failovering Cluster did not install"
	Sleep 600
}
			}

Function Install-SQL	{
	If ((Test-Path C:\PreReqs\SQL.iso))	{
		Mount-DiskImage C:\PreReqs\SQL.iso
		(get-volume | where-object {$_.FileSystemLabel -match "SQLFULL_ENU"}).DriveLetter+":" | cd
		./setup.exe /QUIETSIMPLE /ACTION=install /FEATURES=SQLENGINE,SSMS,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=”NT Authority\System” /SQLSYSADMINACCOUNTS=”BUILTIN\Administrators” /AGTSVCACCOUNT=”NT Authority\System” /SECURITYMODE=SQL /SAPWD=”P@ssW0rd” /SQLTEMPDBDIR=”C:\SQL2012\TempDB\\” /SQLUSERDBDIR=”C:\SQL2012\SQLData\\” /SQLUSERDBLOGDIR=”C:\SQL2012\SQLLog\\” /IACCEPTSQLSERVERLICENSETERMS=1
					}
	Else	{
		Start-BitsTransfer -Source "http://resource.dedicatedcentral.com/software/windows/sql/SQL_2012/ISO/SW_DVD9_SQL_Svr_Standard_Edtn_2012_English_MLF_X17-97001.ISO" -Authentication Basic -Credential $ACreds -Destination C:\PreReqs\SQL.iso | Complete-BitsTransfer
		Install-SQL
		}
	If ((Get-Service | Where-Object {$_.Name -Match "MSSQLSERVER" -and $_.Status -Match "Running"})) {}
	Else{exit}
}

Function Install-SQLHA    {
        If ((Test-Path C:\PreReqs\SQL.iso))     {
                Mount-DiskImage C:\PreReqs\SQL.iso
                (get-volume | where-object {$_.FileSystemLabel -match "SQLFULL_ENU"}).DriveLetter+":" | cd
		./setup.exe /QUIETSIMPLE /ACTION=install /FEATURES=SQLENGINE,SSMS,ADV_SSMS /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT=”NT Authority\System” /SQLSYSADMINACCOUNTS=”BUILTIN\Administrators” /AGTSVCACCOUNT=”NT Authority\System” /SECURITYMODE=SQL /SAPWD=”P@ssW0rd” /IACCEPTSQLSERVERLICENSETERMS=1 /FAILOVERCLUSTERDISKS="SQLServer" "Quorum" /FAILOVERCLUSTERGROUP="SQL Server (SQL0002)" /FAILOVERCLUSTERIPADDRESSES="IPv4;10.0.0.95;Cluster Network 1;255.255.255.0" /FAILOVERCLUSTERNETWORKNAME="SQL02" 
                                        }
        Else    {
		Start-BitsTransfer -Source "http://resource.dedicatedcentral.com/software/windows/sql/SQL_2012/ISO/SW_DVD9_SQL_Svr_Standard_Edtn_2012_English_MLF_X17-97001.ISO" -Authentication Basic -Credential $ACreds -Destination C:\PreReqs\SQL.iso | Complete-BitsTransfer
                Install-SQL
                }
        If ((Get-Service | Where-Object {$_.Name -Match "MSSQLSERVER" -and $_.Status -Match "Running"})) {}
        Else{exit}
}

Function Install-AIK	{
If ((Test-Path C:\PreReqs\AIK.exe))	{
	Write-Host "Installing WAIK"
	C:\PreReqs\aik.exe /features OptionId.WindowsPreinstallationEnvironment OptionId.WindowsPreinstallationEnvironment + /q
	Function Check-AIKStatus	{
		Sleep 10
		$AIKStatus = Get-Process | Where-Object {$_.ProcessName -match "aik"}
		If (($AIKStatus))	{
		Clear
		Write-Host "AIK is still installing"
		Check-AIKStatus
		}
		}
Check-AIKStatus
					}
Else	{
	$80="http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe"
	$81="http://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe"
	Start-BitsTransfer -Source $81 -Destination C:\PreReqs\aik.exe | Complete-BitsTransfer
	Install-AIK
}
}

Function Install-SCVMM	{
	If ((Test-Path C:\PreReqs\SCVMM.iso))	{
        Write-Host "Installing SCVMM 2012 R2"
		Mount-DiskImage C:\PreReqs\SCVMM.iso
		(get-volume | where-object {$_.FileSystemLabel -like "SC*"}).DriveLetter+":" | cd
			Echo "
			[OPTIONS]  
			SqlInstanceName=MSSQLSERVER
			RemoteDatabaseImpersonation=1 
			SqlMachineName=SCVMM-01  
			MUOptIn=1 
			VmmServiceLocalAccount=0
			SQMOptIn=1" > C:\VMM.ini
		.\setup.exe /server /i /f C:\vmm.ini /VmmServiceDomain hvlab02.local /VmmServiceUserName $SCUser /VmmServiceUserPassword $SCPass /IACCEPTSCEULA /SqlDBAdminDomain hvlab02.local /SqlDBAdminName $SCSQLUser /SqlDBAdminPassword $SCSQLPass
	Function Is-VMMInstalled	{
		Sleep 10
		If ((Get-Process | Where-Object {$_.Name -Match "SetupVMM"}))	{
			Write-Host "SCVMM is still installing"
			Clear
			Is-VMMInstalled
										}
		Else	{
	        If ((Get-Service | Where-Object {$_.Name -Match "SCVMMService" -and $_.Status -Match "Running"})) {Write-Host "SCVMM is now installed"}
	        Else{Write-Host "SCVMM has probably failed to be install"}
			}
					}
		Is-VMMInstalled
}
Else	{
	Start-BitsTransfer -Source "http://resource.dedicatedcentral.com/software/Microsoft_OS_ISOs/MS_MISC/MS_SysCtr2012SP1/SW_DVD5_SysCtr_2012_w_SP1_Virtual_Machine_Manager-MultiLang_X18-56747.ISO" -Authentication Basic -Credential $ACreds -Destination C:\PreReqs\SCVMM.iso | Complete-BitsTransfer
	Install-SCVMM
	}

}
Install-SQL
Install-AIK
Install-SCVMM
}
