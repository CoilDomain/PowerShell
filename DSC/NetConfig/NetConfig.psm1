Function Get-TargetResource {
    param
    (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",

    [ValidateNotNullOrEmpty()]
    [string]$Adapter,

    [ValidateSet("Manual", "DHCP")]
    [string]$Type = "DHCP",

    [array]$IPAddress,

    [array]$DNSServers,

    [string]$Gateway,

    [boolean]$RegisterDNS
    )

    $getTargetResourceResult = $null;
    
     $NetworkInformation = @(
        Get-NetIPConfiguration -InterfaceAlias $Adapter
        Get-DNSClient -InterfaceAlias $Adapter
        Get-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4
        )
   
    $getTargetResourceResult = @{
        Ensure = $Ensure
        Adapter = $Adapter
        Type = ($NetworkInformation.SuffixOrigin | Where-Object {$_ -ne $null})
        IPAddress = ($NetworkInformation.IPAddress | Where-Object {$_ -ne $null})
        DNSServers = ($NetworkInformation.DNSServer.ServerAddresses | Where-Object {$_ -ne $null})
        Gateway = $NetworkInformation.IPv4DefaultGateway.NextHop
        RegisterDNS = ($NetworkInformation.RegisterThisConnectionsAddress | Where-Object {$_ -ne $null})
        }

    $getTargetResourceResult;

}

Function Set-TargetResource {
    param
    (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",

    [ValidateNotNullOrEmpty()]
    [string]$Adapter,

    [ValidateSet("Manual", "DHCP")]
    [string]$Type = "DHCP",

    [array]$IPAddress,

    [array]$DNSServers,

    [string]$Gateway,

    [boolean]$RegisterDNS
    )
If ($Ensure -match "Present")   {
    $CurrentIPAddress = Get-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $CurrentGatewayAndDNS = Get-NetIPConfiguration -InterfaceAlias $Adapter -ErrorAction SilentlyContinue

    If ($Type -match "DHCP")    {
        Set-NetIPInterface -InterfaceAlias $Adapter -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceAlias $Adapter -ResetServerAddresses -Confirm:$False
    }
    ElseIf ($Type -match "Manual")   {
    If (!($CurrentIPAddress))   {
        Foreach ($IP in $IPAddress) {
            If (!($Gateway))    { 
                Remove-NetRoute -InterfaceAlias $Adapter -NextHop (Get-NetRoute -InterfaceAlias $Adapter).NextHop -Confirm:$False
                New-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4 -PrefixLength 24 -IPAddres $IP -DefaultGateway $null
            }
            ElseIf ($Gateway)   {
                New-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4 -PrefixLength 24 -IPAddress $IP -DefaultGateway $Gateway
            }
        }
    }
    If ($CurrentIPAddress)  {
        $Difference = Compare-Object ($CurrentIPAddress|Sort-Object) ($IPAddress|Sort-Object)
        Foreach ($Diff in $Difference)  {
            If ($Diff.SideIndicator -match "<=")    {
                Remove-NetIPAddress -InterfaceAlias $Adapter -IPAddress $Diff.InputObject.IPaddress -Confirm:$false
            }
            ElseIf ($Diff.SideIndicator -match "=>")    {
                New-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4 -PrefixLength 24 -IPAddress $Diff.InputObject
            }
        }
        If (!($Gateway)) {
            Remove-NetRoute -InterfaceAlias $Adapter -NextHop (Get-NetRoute -InterfaceAlias $Adapter).NextHop -Confirm:$False
        }
        ElseIf ($Gateway) {
            If (!(Get-NetRoute -InterfaceAlias $Adapter | Where-Object {$_.DestinationPrefix -match "0.0.0.0/0"})) {
                New-NetRoute -InterfaceAlias $Adapter -NextHop $Gateway -DestinationPrefix "0.0.0.0/0"
            }
        }
    }
    If (!($DNSServers)) {
        Set-DnsClientServerAddress -InterfaceAlias $Adapter -ResetServerAddresses -Confirm:$False
        }
    ElseIf ($DNSServers) {
        Set-DnsClientServerAddress -InterfaceAlias $Adapter -ServerAddresses $DNSServers -Confirm:$False
        }
    If (!($RegisterDNS)) {
        Set-DnsClient -InterfaceAlias $Adapter -RegisterThisConnectionsAddress:$false
        }
    ElseIf ($RegisterDNS) {
        Set-DnsClient -InterfaceAlias $Adapter -RegisterThisConnectionsAddress:$true
        }
}
}
ElseIf ($Ensure -match "Absent") {
    Set-DnsClient -InterfaceAlias $Adapter -RegisterThisConnectionsAddress:$false
    Set-DnsClientServerAddress -InterfaceAlias $Adapter -ResetServerAddresses -Confirm:$False
    Set-NetIPInterface -InterfaceAlias $Adapter -Dhcp Enabled
    }
}

Function Test-TargetResource {
    param
    (
    [ValidateSet("Present", "Absent")]
    [string]$Ensure = "Present",

    [ValidateNotNullOrEmpty()]
    [string]$Adapter,

    [ValidateSet("Manual", "DHCP")]
    [string]$Type = "DHCP",

    [array]$IPAddress,

    [array]$DNSServers,

    [string]$Gateway,

    [boolean]$RegisterDNS
    )

    $Valid = $True

If ($Ensure -match "Present")   {

$CurrentIPAddresses = Get-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4
$CurrentDNSServers = (Get-DnsClientServerAddress -InterfaceAlias $Adapter -AddressFamily IPv4).ServerAddresses
$IPComparison = Compare-Object ($CurrentIPAddresses|Sort-Object) ($IPAddress|Sort-Object)
$DNSComparison = Compare-Object ($CurrentDNSServers|Sort-Object) ($DNSServers|Sort-Object)
$DefaultGW = (Get-NetIPConfiguration -InterfaceAlias $Adapter).IPv4DefaultGateway

    If ($Type -match "DHCP") {
        If ((Get-NetIPInterface -InterfaceAlias $Adapter).Dhcp -match "Disabled") {
            $Valid = $False
        }
    }
    ElseIf ($Type -match "Manual") {
    $DNSComparison
        If ((Get-NetIPInterface -InterfaceAlias $Adapter -AddressFamily IPv4).Dhcp -match "Enabled") {
            $Valid = $False
        }
        If ($DNSComparison) {
            $Valid = $False
        }
        If ($IPComparison) {
            $Valid = $False
        }
        If (!($Gateway)) {
            If ($DefaultGW) {
                $Valid = $False
            }
        }
        ElseIf ($Gateway) {
            If ($Gateway -notmatch $DefaultGW) {
            write-host break5
                $Valid = $False
            }
        }
        If (!($RegisterDNS)) {
            If ((Get-DnsClient -InterfaceAlias $Adapter).RegisterThisConnectionsAddress -match $True) {
                $Valid = $False
            }
        }
        ElseIf ($RegisterDNS) {
            If ((Get-DnsClient -InterfaceAlias $Adapter).RegisterThisConnectionsAddress -match $False) {
                $Valid = $False
            }
        }                      
}
}
ElseIf ($Ensure -match "Absent") {

    }
$Valid
}
