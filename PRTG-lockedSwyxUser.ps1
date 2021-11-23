# Dieses PRTG-Skript prüft ob ein SwyxUser mit RemoteConnectorLogin deaktivert ist
# Stannek GmbH - v.1.01 - E.Sauerbier 23.11.2021

# Parameter für den PRTG-Sensor
param([string]$SwyxServer = "N/A",[string]$Password = "N/A",$SwyxAdmin = "N/A",[string]$Domain = "N/A")

# Credentials für SwyxPS Anmeldung erstellen
$SwyxAdminPass = ConvertTo-SecureString -AsPlainText $Password -Force
$SwyxSRVCred = New-Object System.Management.Automation.PSCredential -ArgumentList $SwyxAdmin,$SwyxAdminPass

# Abfrage auf dem Swyx-Server
$lockedSwyxUser = @( Invoke-Command -cn $SwyxServer -Credential $SwyxSRVCred -ScriptBlock {
&'C:\Program Files (x86)\SwyxWare Administration\Modules\IpPbx\IpPbxConsole.ps1' 'SwyxWare PowerShell'
Connect-IpPbx
Get-IpPbxUser | Where {$_.Locked -eq $True -and $_.WindowsLoginAllowed -eq $True -and $_.IsCertificateThumbprintNull -eq $false}
})

# XML Ausgabe für PRTG
#"<?xml version=`"1.0`" encoding=`"UTF-8`" ?>"
"<prtg>"
"<result>"
"<channel>deaktivierte SwyxUser</channel>"
"<value>"+$lockedSwyxUser.Count+"</value>"
"</result>"
"<text>Folgende SwyxUser sind deaktiviert: "+$lockedSwyxUser.Name+"</text>"
"</prtg>"
