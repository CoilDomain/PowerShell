Function Get-OutlookInBox
{
Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
$outlook = new-object -comobject outlook.application
$namespace = $outlook.GetNameSpace("MAPI")
$folder = $namespace.getDefaultFolder($olFolders::olFolderInbox)
$folder.items
}
$Emails=(Get-OutlookInBox | where-object {$_.subject -eq "VM Creation"} | Select -First 1)
Foreach ($Email in $Emails){
$String=$Email.body | Out-String
$SubString=$String.Replace('Body : ',"`n")
$SubString=$SubString -Split "`n"
$VMName=($SubString | Where-Object {$_ -like "Name*"}).Trim()
$VMCPU=($SubString | Where-Object {$_ -like "CPU*"}).Trim()
$VMRAM=($SubString | Where-Object {$_ -like "RAM*"}).Trim()
$CDRIVE=($SubString | Where-Object {$_ -like "CDrive*"}).Trim()
$DDRIVE=($SubString | Where-Object {$_ -like "DDrive*"}).Trim()
If ($VMName -like "Name*" -and $VMCPU -like "CPU*" -and $VMRAM -like "RAM*" -and $CDRIVE -like "CDrive*" -and $DDRIVE -like "DDrive*"){
$VMConfig=@{"Name" = $VMName.Replace('Name: ',''); "CPU" = $VMCPU.Replace('CPU: ',''); "CDrive" = $CDRIVE.Replace('CDrive: ',''); "DDrive" = $DDRIVE.Replace('DDrive: ',''); "RAM" = $VMRAM.Replace('RAM: ','')}
$VMConfig
}
}