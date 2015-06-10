Function Install-Kaseya ($ServerName) {
$AgentURL=
If (!(Get-Process AgentMon -ComputerName $ServerName -ErrorAction SilentlyContinue)) {
New-Item -Type Directory \\$ServerName\C$\Support -ErrorAction SilentlyContinue
Start-BitsTransfer $AgentURL -Destination \\$ServerName\C$\Support\KcsSetup.exe | Complete-BitsTransfer
Invoke-Command -ComputerName $ServerName -ScriptBlock {cmd /C C:\Support\KcsSetup.exe /s}
}
}