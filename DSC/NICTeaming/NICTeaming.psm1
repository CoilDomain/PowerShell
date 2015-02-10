Function Get-TargetReSource
{
    param
    (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",

    [ValidateNotNullOrEmpty()]
    [string]$Name,
    
    [ValidateSet("SwitchIndependent", "LACP", "Static")]
    [string]$Mode = "SwitchIndependent",

    [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
    [string]$LBMode = "Dynamic",

    [array]$VlanID,

    [Parameter(Mandatory)]
    [array]$NICs
    )
    
    $getTargetResourceResult = $null;

    #########################################Logic##############################################

    $Team = Get-NetLBFOTeam -Name $Name
    $TeamNIC = $Team | Get-NetLBFOTeamNIC | Where-Object {$_.VlanID -match $VlanID}

    If (($Team.name -match $Name) -and ($Team.Members -match $Nics) -and ($TeamNIC.VlanID -match $VlanID))  #Or Default?
    {
        $ensureResult = $true
    }
    Else
    {
        $ensureResult = $false
    }

    ########################################Results#############################################

    $getTargetResourceResult = @{
            Name    = $Team.Name
            Ensure  = $ensureResult;
            Mode    = $Team.TeamingMode
            LBMode  = $Team.LoadBalancingAlgorithm
            VlanID  = $TeamNIC.VlanID
            NICs    = $Team.Members
    }

    $getTargetResourceResult;

}

Function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",

    [Parameter(Mandatory)]
    [string]$Name,

    [ValidateSet("SwitchIndependent", "LACP", "Static")]
    [string]$Mode = "SwitchIndependent",

    [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
    [string]$LBMode = "Dynamic",

    [array]$VlanID,

    [Parameter(Mandatory)]
    [array]$NICs
    )
    #########################################Logic##############################################

If ($Ensure -match "Present")   {
        #Check if team exists already, if not make it
        If (!(Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue))   {
        #Create Teaming
            New-NetLBFOTeam -Name $Name -LoadBalancingAlgorithm $LBMode -TeamingMode $Mode -TeamMembers $NICs -TeamNicName $Name -Confirm:$False
            Sleep 5 #PS Command is too fast, resulting in missing object?!
            Set-DNSClient -InterfaceAlias $Name -RegisterThisConnectionsAddress:$True
                                                                            }
        #Setup VLANs -- If multiple VLANs are set, it will create a new virtual NIC for each one.
        If (!($VlanID)) {
        #If a VLAN isn't specified it will set it as an untagged virtual NIC.
            Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamNic | Where-Object {$_.Primary -notmatch "True"} | Remove-NetLbfoTeamNic -Confirm:$False
            Sleep 5 #PS Command is too fast, resulting in missing object?!
            Set-DNSClient -InterfaceAlias $Name -RegisterThisConnectionsAddress:$True
                        }
        Else    {
        #Remove all VLANs no longer used
        $UsedVLANs = (Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamNic | Where-Object {$_.Primary -notmatch "True"}).VlanID
        If (!($UsedVLANs))  {
            Foreach ($VLAN in $VlanID)  {
            Add-NetLBFOTeamNIC -VlanID $VLAN -Team $Name -Confirm:$False
                                        }
                            }
        Else    {
        $VLANs = Compare-Object $UsedVLANs $VlanID -IncludeEqual -ErrorAction SilentlyContinue
            Foreach ($VLAN in $VLANs)   {
                If ($VLAN.SideIndicator -match "<="){
                Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamNic | Where-Object {$_.VlanID -match $VLAN.InputObject} | Remove-NetLbfoTeamNic -Confirm:$False
                    }
                ElseIf ($VLAN.SideIndicator -match "=="){}
                ElseIf ($VLAN.SideIndicator -match "=>")    {
                Add-NetLBFOTeamNIC -VlanID $VLAN.InputObject -Team $Name -Confirm:$False
                                                            }
                                        }
                }

                }
        $UsedNetAdapters = (Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamMember).Name
        $NetAdapters = Compare-Object $UsedNetAdapters $NICs -IncludeEqual
        $AdditionalNICs = ($NetAdapters | Where-Object {$_.SideIndicator -match "=>"}).InputObject
        $NicsToBeRemoved = ($NetAdapters | Where-Object {$_.SideIndicator -match "<="}).InputObject
            If (($AdditionalNICs)){Add-NetLbfoTeamMember -Team $Name -Name  $AdditionalNICs -Confirm:$False}
            If (($NicsToBeRemoved)){Remove-NetLbfoTeamMember -Team $Name -Name $NicsToBeRemoved -Confirm:$False}
        $UsedMode = (Get-NetLbfoTeam -Name $Name).TeamingMode
        $UsedLBMode = (Get-NetLbfoTeam -Name $Name).LoadBalancingAlgorithm
            If ((Compare-Object $Mode $UsedMode) -notmatch "=="){Set-NetLbfoTeam -Name $Name -TeamingMode $Mode}
            If ((Compare-Object $LBMode $UsedLBMode) -notmatch "=="){Set-NetLbfoTeam -Name $Name -LoadBalancingAlgorithm $LBMode}
                                }
If ($Ensure -match "Absent")	{
        If (!(Get-NetLbfoTeam -Name $Name)){}
        If ((Get-NetLbfoTeam -Name $Name)){Remove-NetLbfoTeam -Name $Name -Confirm:$False}
                            	}

}

Function Test-TargetResource
{
    param
    (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",
 
    [ValidateNotNullOrEmpty()]
    [string]$Name,
 
    [ValidateSet("SwitchIndependent", "LACP", "Static")]
    [string]$Mode = "SwitchIndependent",
 
    [ValidateSet("Dynamic", "HyperVPort", "IPAddresses", "MacAddresses", "TransportPorts")]
    [string]$LBMode = "Dynamic",
 
    [array]$VlanID,
 
    [Parameter(Mandatory)]
    [array]$NICs
    )
   
    $Valid = $True
If ($Ensure -match "Present") {
    If (!(Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue)) {
        Write-Verbose "Team $Name does not exists"
        $Valid = $Valid -and $false
        }
    ElseIf ((Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue)) {
        If (!(Get-NetLbfoTeam -Name $Name | Where-Object {$_.LoadBalancingAlgorithm -match $LBMode})) {
        Write-Verbose "Load Balancing Algorithm does not match $LBMode"
        $Valid = $Valid -and $false
        }
        If (!(Get-NetLbfoTeam -Name $Name | Where-Object {$_.TeamingMode -match $Mode})) {
        Write-Verbose "Teaming mode does not match $Mode"
        $Valid = $Valid -and $false
        }
        If (!($VlanID) -and ((Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamNic).VlanID)) {
        Write-Verbose "There are VLANs used where no VLANs should be configured"
        $Valid = $Valid -and $false
        }
        ElseIf (($VlanID)){
        $UsedVLANs = (Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamNic | Where-Object {$_.Primary -notmatch "True"}).VlanID
        If (($UsedVLANs)){
        $VLANs = Compare-Object $UsedVLANs $VlanID -IncludeEqual -ErrorAction SilentlyContinue
        Foreach ($VLAN in $VLANs){
            If ($VLAN.SideIndicator -match "<="){
            $Valid = $Valid -and $false
            Write-Verbose "VLAN $($VLAN.InputObject) shouldn't exist"
            }
            ElseIf ($VLAN.SideIndicator -match "=>"){
            $Valid = $Valid -and $false
            Write-Verbose "VLAN $($VLAN.InputObject) should exist"
            }
            }
            }
        ElseIf (!($UsedVLANs)){
        $Valid = $Valid -and $false
            Foreach ($VLAN in $VlanID){
            Write-Verbose "VLAN $VLAN should exist, but doesn't"
            }
            }
            }
        $UsedNetAdapters = (Get-NetLbfoTeam -Name $Name | Get-NetLbfoTeamMember).Name
        $NetAdapters = Compare-Object $UsedNetAdapters $NICs -IncludeEqual
        Foreach ($NetAdapter in $NetAdapters){
            If ($NetAdapter.SideIndicator -match "=="){}
            ElseIf ($NetAdapter.SideIndicator -match "<="){
            Write-Verbose "NIC $($NetAdapter.InputObject) should not be in this team"
            $Valid = $Valid -and $false
            }
            ElseIf ($NetAdapter.SideIndicator -match "=>"){
            Write-Verbose "NIC $($NetAdapter.InputObject) should be in this team"
            $Valid = $Valid -and $false
            }
            }
}
}
ElseIf  ($Ensure -match "Absent") {
        If ((Get-NetLBFOTeam -Name $Name -ErrorAction SilentlyContinue)) {
        Write-Verbose "There is a team where there should not be"
        $Valid = $Valid -and $false
        }
} 
    return $valid
}
