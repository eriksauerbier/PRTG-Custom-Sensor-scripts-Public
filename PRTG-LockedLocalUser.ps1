# Dieses PRTG-Skript prüft ob ein Lokaler Benutzer gesperrt ist
# Stannek GmbH - E.Sauerbier - v.1.1.1 - 17.11.2023

# Lokale User Abfrage
$lockedAccounts = @(Get-WmiObject win32_useraccount -filter "LockOut=True")

# Text für Ausgabe generieren
if ($lockedAccounts.count -gt "0") {$TextPRTGSensor = "Folgende lokale Benutzer sind gesperrt: "+$lockedAccounts.name}
Else {$TextPRTGSensor = "Es sind keine lokalen Benutzer gesperrt"}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Locked Users</channel>`n" 
$OutputStringXML += "<value>"+$lockedAccounts.count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML