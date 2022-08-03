# Dieses PRTG-Skript prüft ob ein SwyxUser mit RemoteConnectorLogin deaktivert ist
# Stannek GmbH - E.Sauerbier - v.1.1 - 03.08.2022

# Parameter für den PRTG-Sensor
param([string]$SwyxServer = " ",[string]$Password = " ",[string]$SwyxAdmin = " ")

# Credentials für SwyxPS Anmeldung erstellen
$SwyxAdminPass = ConvertTo-SecureString -AsPlainText $Password -Force
$SwyxSRVCred = New-Object System.Management.Automation.PSCredential -ArgumentList $SwyxAdmin,$SwyxAdminPass

# Abfrage auf dem Swyx-Server
$lockedSwyxUser = @(Invoke-Command -cn $SwyxServer -Credential $SwyxSRVCred -ErrorAction Stop -ScriptBlock {
# Swyx PS-Modul importieren
Import-Module IpPbx
# Mit Swyx Instanz verbinden
Connect-IpPbx
# User Abfrage starten
Get-IpPbxUser | Where-Object {$_.Locked -eq $True -and $_.WindowsLoginAllowed -eq $True -and $_.IsCertificateThumbprintNull -eq $false}
# Swyx Instanz trennen
Disconnect-IpPbx
})

# Text für Ausgabe generieren

if ($lockedSwyxUser.Count -gt "0") {$OutputText = "Folgende Swyx Benutzer sind deaktiviert: "+$lockedSwyxUser.Name}
Else {$OutputText = "Es sind keine Swyx Benutzer deaktiviert"}

# XML Ausgabe für PRTG
#"<?xml version=`"1.0`" encoding=`"UTF-8`" ?>"
"<prtg>"
"<result>"
"<channel>deaktivierte SwyxUser</channel>"
"<value>"+$lockedSwyxUser.Count+"</value>"
"</result>"
"<text>$OutputText</text>"
"</prtg>"