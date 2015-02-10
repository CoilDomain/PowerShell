function Add-SPFTenant ($TenantFQDN, $StampName, $Certificate)	{
#### Tenent addition portion
	$Stamp = Get-SCSPFStamp -Name $StampName
	$Tenant = New-SCSPFTenant –Name “CN=$TenantFQDN” –IssuerName “CN=$TenantFQDN” –Stamps $stamp –Key (Get-Content $Certificate)
	$TARole = New-SCUserRole –Name CN=$TenantFQDN –ID $tenant.Id -UserRoleProfile TenantAdmin
	$TenantSSU = New-SCSPFTenantUserRole -Tenant $Tenant -Name $TenantFQDN-SSU
	$VMMSSU = New-SCUserRole -Name $TenantFQDN-SSU -UserRoleProfile SelfServiceUser -ParentUserRole $TARole -ID $TenantSSU.ID
#### VMM Cloud creation portion
	$CloudJobGroup = [System.Guid]::NewGuid()
	Set-SCCloudCapacity -JobGroup "$CloudJobGroup" -UseCustomQuotaCountMaximum $true -UseMemoryMBMaximum $true -UseCPUCountMaximum $true -UseStorageGBMaximum $true -UseVMCountMaximum $true

	$resources = @()
	$resources += Get-SCLogicalNetwork -ID "ad9c45dd-1064-4d89-8a24-bd2394162de8" #GUID of the Logical Network
	$readonlyLibraryShares = @()
	$readonlyLibraryShares += Get-SCLibraryShare -ID "d0fe83bc-094f-485e-9158-7624c92d22a0" #GUID of the library share, think Smart_Cloud_Library

	$addCapabilityProfiles = @()
	$addCapabilityProfiles += Get-SCCapabilityProfile -Name "Hyper-V"

	Set-SCCloud -JobGroup "$CloudJobGroup" -RunAsynchronously -AddCloudResource $resources -AddReadOnlyLibraryShare $readonlyLibraryShares -AddCapabilityProfile $addCapabilityProfiles

	$hostGroups = @()
	$hostGroups += Get-SCVMHostGroup -ID "246b0bbd-e056-46aa-a319-4624d79a5907" #GUID of the hostgroup
	New-SCCloud -JobGroup "$CloudJobGroup" -VMHostGroup $hostGroups -Name "$TenantFQDN" -Description "" -RunAsynchronously
#### Add SSU/Tenant admin to Cloud
	$CloudJobGroup = [System.Guid]::NewGuid()
	$cloud = Get-SCCloud -ID "3dd9b5b2-9ded-4414-aa2e-bb7c737c82ca" #GUID of the previously create Cloud
        Set-SCUserRoleQuota -Cloud $cloud -JobGroup "$CloudJobGroup"
        Set-SCUserRoleQuota -Cloud $cloud -JobGroup "$CloudJobGroup" -QuotaPerUser
        $userRole = Get-SCUserRole -Name "Test01" -ID "b967501a-2dd6-4911-98e2-091e914eac92" #Name and GUID of the tenant admin
        $scopeToAdd = @()
        $scopeToAdd += Get-SCCloud -ID "3dd9b5b2-9ded-4414-aa2e-bb7c737c82ca" #GUID of the Cloud previously made
        Set-SCUserRole -UserRole $userRole -Description "" -JobGroup "$CloudJobGroup" -Name "Test01" -AddScope $scopeToAdd -Permission @("Author", "AuthorVMNetwork", "Checkpoint", "CreateFromVHDOrTemplate", "AllowLocalAdmin", "PauseAndResume", "RemoteConnect", "Remove", "Save", "Shutdown", "Start", "Stop", "Store") -ShowPROTips $false


								}
