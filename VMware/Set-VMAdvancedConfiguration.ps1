function Set-VMAdvancedConfiguration {   
<#  
.SYNOPSIS  
  Sets an advanced configuration setting (VMX Setting) for a VM  
  or multiple VMs  
.DESCRIPTION  
  The function will set a VMX setting for a VM  
  or multiple VMs  
.NOTES  
  Source:  Automating vSphere Administration  
  Authors: Luc Dekens, Arnim van Lieshout, Jonathan Medd,  
           Alan Renouf, Glenn Sizemore  
  Adjusted: 07 June 2012 by Alan Renouf to accept a list of options  
.PARAMETER VM  
  A virtual machine or multiple virtual machines  
.PARAMETER Key  
  The Key to use for the advanced configuration  
.PARAMETER Value  
  The value of the key  
.EXAMPLE 1  
  PS> Set-VMAdvancedConfiguration -key log.rotatesize -value 10000  
.EXAMPLE 2  
  PS> $file = Import-Csv c:\tmp\Settings.txt -Header Key,Value  
  PS> Set-VMAdvancedConfiguration -vm $VM -OptionList $file  
#>  
  param(  
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]  
      $vm,  
      [String]$key,  
      [String]$value,  
      [Array]$OptionList  
      )  
  process{   
    $vmConfigSpec = new-object VMware.Vim.VirtualMachineConfigSpec  
    If ($OptionList) {  
        $OptionList | Foreach {  
            $Values = new-object vmware.vim.optionvalue  
            $Values.key=$_.key  
            $Values.value=$_.value  
            $vmConfigSpec.ExtraConfig += $Values  
            Write-Host "Adding $($_.Key) = $($_.Value)"  
        }  
    } Else {  
        $vmConfigSpec.ExtraConfig += new-object VMware.Vim.OptionValue  
        $vmConfigSpec.ExtraConfig[0].key = $key  
        $vmConfigSpec.ExtraConfig[0].value = $value  
        Write-Host "Adding $Key = $Value"  
    }  
    foreach ($singlevm in $vm) {  
      $Task = ($singlevm.ExtensionData).ReconfigVM_Task($vmConfigSpec)  
      Write "Set Advanced configuration for $($singleVM.Name)"  
    }  
  }   
}  

