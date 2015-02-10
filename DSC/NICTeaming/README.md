NIC Teaming DSC Provider
==

####Installation Guide:

Copy folder to C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PSProviders and run:

        $MOF = Get-Content C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PSProviders\NICTeaming\NICTeaming.schema.mof
        $MOF | Out-FIle -Encoding ascii -filepath C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PSProviders\NICTeaming\NICTeaming.schema.mof -Force

This will turn the UTF-8 encode file into ASCII, which will fix parsing issues with DSC

####Example:

        Configuration Team
        {
        # A Configuration block can have zero or more Node blocks
        Node TestNode
          {
          Teaming Test
            {
              Ensure = "Present"
              Name = "Test"
              NICs = "Ethernet", "Ethernet 2" 
              #Mode is not required as it defaults to SwitchIndependent, you have the options of LACP, SwitchIndependent, and Static
              Mode = "Static"
              #LBMode is not required as it defaults to Dynamic, you have the options of Dynamic, HyperVPort, IPAddresses, MacAddresses, or TransportPorts
              LBMode = "IPAddresses"
              #Specifying VLANs is optional, otherwise your port will be made as native(untagged)
              VlanID = "100", "200"
            }
          }
        }
        Team
        Start-DscConfiguration -Wait -Verbose -Path .\Team
