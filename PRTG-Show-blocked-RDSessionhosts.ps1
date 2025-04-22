# PRTG-Skript zum Anzeigen der RD-Sessionhosts mit gesperrter Anmeldung
# Stannek GmbH - v.1.4 - 22.04.2025 - E.Sauerbier

# Beachte dass dieses Skript nur mit der 64Bit Powershell läuft, 
# hierzu muss ein mittels PRTG ein "Start-Skript" gestartet werden, da die Probe nur als 32Bit-Version verfügbar ist (Stand 05.2022)

# TSFarmen auslesen
$Collections = Get-RDSessionCollection

# Objectvariable erstellen
$SessionHosts = @()

# RD-SessionHosts auslesen
Foreach ($Collection in $Collections) {
            $SessionHosts += $Collection | Get-RDSessionHost
            }

# gesperrte Hosts auslesen
$BlockedHosts = $SessionHosts | Where NewConnectionAllowed -eq No

# Ausgabetext generieren 
if ($Null -eq $blockedHosts) {$TextPRTGSensor = "Es sind keine Sessionhosts gesperrt"}
Else {$TextPRTGSensor = "An folgenden Sessionhosts ist die Anmeldung gesperrt: " + $blockedHosts.SessionHost}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Gesperrte Sessionhosts</channel>`n" 
$OutputStringXML += "<value>"+$BlockedHosts.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Anzahl der Sessionhosts</channel>`n" 
$OutputStringXML += "<value>"+$SessionHosts.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Anzahl der Sammlungen</channel>`n" 
$OutputStringXML += "<value>"+$Collections.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML