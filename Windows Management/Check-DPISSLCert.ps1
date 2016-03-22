If (!(ls C:\Support)) {mkdir C:\Support}
if (!(get-command psexec.exe)) {

Start-BitsTransfer https://download.sysinternals.com/files/PSTools.zip -Destination C:\Support\

$shell = new-object -com shell.application
$zip = $shell.NameSpace(“C:\Support\PSTools.zip”)
foreach($item in $zip.items())
{
$shell.Namespace(“C:\Windows\System32”).copyhere($item)
}
}
If (!(ls C:\Support\CertCheck)) {mkdir C:\Support\CertCheck}
import-module activedirectory
$Computers=Get-ADComputer -Property * -filter {(OperatingSystem -notlike "Windows Server*") -and (enabled -eq "True")}

$computers | foreach {
$ComputerName=$_.Name

If (( Test-Connection $ComputerName -Count 1 -TimeToLive 1 -ErrorAction SilentlyContinue)) {psexec \\$ComputerName certutil -store root | findstr "SonicWALL" > C:\Support\CertCheck\$ComputerName.txt}

ElseIf (!( Test-Connection $ComputerName -Count 1 -TimeToLive 1 -ErrorAction SilentlyContinue)) {Write-Output "Offline" | Out-File C:\Support\CertCheck\$ComputerName.txt}
}

$FullReport=@()
ls C:\Support\CertCheck | foreach {
If ((Get-Content $_.FullName | findstr "Issuer: CN=SonicWALL Firewall DPI-SSL, O=SonicWALL Inc., S=CA, C=US") -and !(Get-Content $_.FullName | findstr "Offline")) {
$Report=New-Object System.Object
$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name.Replace(".txt","")
$Report | Add-Member -Type NoteProperty -Name HasSSLCert -Value True
$FullReport+=$Report
}
If (!(Get-Content $_.FullName | findstr "Issuer: CN=SonicWALL Firewall DPI-SSL, O=SonicWALL Inc., S=CA, C=US") -and !(Get-Content $_.FullName | findstr "Offline")) {
$Report=New-Object System.Object
$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name.Replace(".txt","")
$Report | Add-Member -Type NoteProperty -Name HasSSLCert -Value False
$FullReport+=$Report
}
If ((Get-Content $_.FullName | findstr "Offline") -and !(Get-Content $_.FullName | findstr "Issuer: CN=SonicWALL Firewall DPI-SSL, O=SonicWALL Inc., S=CA, C=US")) {
$Report=New-Object System.Object
$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name.Replace(".txt","")
$Report | Add-Member -Type NoteProperty -Name HasSSLCert -Value Offline
$FullReport+=$Report
}
}

$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
<title>
Title of my Report
</title>
"@

$FullReport | Where-Object {$_.HasSSLCert -match "True"} | ConvertTo-HTML -Head $Header | Out-File C:\Support\CertCheck\Report-HasCert.html
$FullReport | Where-Object {$_.HasSSLCert -match "False"} | ConvertTo-HTML -Head $Header | Out-File C:\Support\CertCheck\Report-MissingCert.html
$FullReport | Where-Object {$_.HasSSLCert -match "Offline"} | ConvertTo-HTML -Head $Header | Out-File C:\Support\CertCheck\Report-Offline.html
