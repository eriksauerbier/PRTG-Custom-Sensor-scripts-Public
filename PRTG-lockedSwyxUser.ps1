# Dieses PRTG-Skript prüft ob ein SwyxUser mit RemoteConnectorLogin deaktivert ist
# Stannek GmbH - E.Sauerbier - v.1.2 - 07.11.2023

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
Get-IpPbxUser | Where-Object {$_.Locked -eq $True -and $_.WindowsLoginAllowed -eq $True -and $_.IsCertificateThumbprintNull -eq $false -and $_.Comment -ne "OK"}
# Swyx Instanz trennen
Disconnect-IpPbx
})

# Text für Ausgabe generieren
if ($lockedSwyxUser.Count -gt "0") {$TextPRTGSensor = "Folgende Swyx Benutzer sind deaktiviert: "+$lockedSwyxUser.Name}
Else {$TextPRTGSensor = "Es sind keine Swyx Benutzer deaktiviert"}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>deaktivierte SwyxUser</channel>`n" 
$OutputStringXML += "<value>"+$lockedSwyxUser.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML