If (!(Get-Module | Where-Object {$_.Name -match "activedirectory"})){import-module activedirectory}
If (!(Get-Module | Where-Object {$_.Name -like "*.domain.com"})){. 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto}

$HostingOUs=""

Foreach ($OU in $HostingOUs) {

$CompanyOUs=Get-OrganizationalUnit $OU -SingleNodeOnly | Where-Object {$_.Name -notmatch $OU}
Foreach ($CompanyOU in $CompanyOUs) {
$OutFile=$CompanyOU.Name.Replace(" ", "")
$Users=Get-ADUser -filter 'enabled -eq $true' -Property * | Where-object {$_.DistinguishedName -match $CompanyOU.DistinguishedName}
$FullReport=@()
$Users | Foreach {
	$ErrorActionPreference = "silentlycontinue"
	$DistinguishedName=$_.DistinguishedName | out-string
	$Object = [adsi]"LDAP://$DistinguishedName"
	$Mailbox=Get-Mailbox $_.SamAccountName -ErrorAction SilentlyContinue
	$Report=New-Object System.Object
	$Report | Add-Member -Type NoteProperty -Name Name -Value $_.Name
	$Report | Add-Member -Type NoteProperty -Name UserName -Value $_.SamAccountName
	If (($Mailbox))	{
		$LastLogon=((Get-Date) - ((Get-MailboxStatistics $_.SamAccountName).lastlogontime)).Days
		$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $Mailbox.PrimarySMTPAddress
		$Report | Add-Member -Type NoteProperty -Name LastLogonDate -Value (Get-MailboxStatistics $_.SamAccountName).lastlogontime
		$Report | Add-Member -Type NoteProperty -Name DaysSinceLastLogon -Value $LastLogon
			}
	ElseIf (!($MailBox))	{
		$LastLogon=((Get-Date) - $_.LastLogonDate).Days
		$Report | Add-Member -Type NoteProperty -Name "Email Address" -Value $Mailbox.PrimarySMTPAddress
		$Report | Add-Member -Type NoteProperty -Name LastLogonDate -Value $_.LastLogonDate
		$Report | Add-Member -Type NoteProperty -Name DaysSinceLastLogon -Value $LastLogon
				}
	$Report | Add-Member -Type NoteProperty -Name LastLogonDate -Value $_.LastLogonDate
	$Report | Add-Member -Type NoteProperty -Name DaysSinceLastLogon -Value $LastLogon
	$Report | Add-Member -Type NoteProperty -Name CreationDate -Value $_.WhenCreated
	If (($Object.psbase.invokeget(“TerminalServicesProfilePath“))) {$Report | Add-Member -Type NoteProperty -Name "Desktop User" -Value "True"}
	ElseIf (!($Object.psbase.invokeget(“TerminalServicesProfilePath“))) {$Report | Add-Member -Type NoteProperty -Name "Desktop User" -Value "False"}
	$FullReport+=$Report
}
$Count=($Users | measure).Count
$Company=$CompanyOU.Name
$FullReport | Export-CSV $Company".csv"
$File=(ls | Where-Object {$_.Name -match $Company}).FullName
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"
$smtpServer = ""
$smtpFrom = ""
$smtpTo = ""
$messageSubject = "User Report: $Company"
$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
$attachment = New-Object System.Net.Mail.Attachment($emailattachment, 'text/plain')
$message.Attachments.Add($file)
$message.Subject = $messageSubject
$message.IsBodyHTML = $true
$message.Body = "<h2>Enabled Users</h2><br><br>"
$message.Body = $message.Body + "Shows all enabled users<br><br>"
$message.Body = $message.Body + "Scope: $CompanyOU<br><br>"
$message.Body = $message.Body + "Number of users: $Count<br><br>"
$message.Body = $message.Body + ($FullReport |  convertto-html -Head $style)
$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($message)
Write-Host "Sent"
}
}