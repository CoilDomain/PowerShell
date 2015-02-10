####vSphere Datastore usage####
add-pssnapin Vmware.VIMAutomation.Core
$username = "domain\username"
$password = "password"
$vihost = "hostname"

function Get-Storage{
Connect-VIServer $vihost -username $username -password $password
Get-Datastore | Select Name, CapacityGB
					}
Get-Storage > "C:\Output.log"

function EmailStats	{
	$EmailFrom = "sender@domain.com"
	$EmailTo = "receiver@domain.com" 
	$Subject = "Storage Statistics" 
	$Body = Get-Content "C:\Output.log" | out-string
	$SMTPServer = "smtp server" 
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
	$SMTPClient.EnableSsl = $true 
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("email username", "email password"); 
	$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
					}
EmailStats