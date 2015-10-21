Add-Type -AssemblyName microsoft.office.interop.outlook
$olFolders = "Microsoft.Office.Interop.Outlook.OlDefaultFolders" -as [type]
$outlook = New-Object -ComObject outlook.application
$namespace = $Outlook.GetNameSpace("mapi")
$inbox = $namespace.getDefaultFolder($olFolders::olFolderInbox)
$MoveTarget = $inbox.Folders.item("VM Creation")
$onedayback = (get-date).AddDays(-10)
$items = $inbox.items
$filter = "[Subject] = 'VM Creation'"
$inbox = $namespace.GetDefaultFolder($olFolders::olFolderInbox).Items.Restrict($filter)
$inbox.count
$Emails = $inbox

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

$Email.Move($MoveTarget) | out-null

}
}