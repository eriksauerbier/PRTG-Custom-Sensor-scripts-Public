# PRTG-Skript zum Anzeigen der RD-Sessionhosts mit gesperrter Anmeldung
# Stannek GmbH - v.1.1 - 30.05.2022 - E.Sauerbier

# Beachte dass dieses Skript nur mit der 64Bit Powershell läuft, 
# hierzu muss ein mittels PRTG ein "Start-Skript" gestartet werden, da die Probe nur als 32Bit-Version verfügbar ist (Stand 05.2022)

# RD-SessionHosts auslesen
$SessionHost = Get-RDSessionCollection | Get-RDSessionHost

# gesperrte Hosts auslesen
$blockedHosts = $SessionHost | Where NewConnectionAllowed -eq No

# Ausgabetext generieren 
if ($blockedHosts -eq $Null) {$OutputText = "Es sind keine Sessionhosts gesperrt"}
Else {$OutputText = "An folgenden Sessionhosts ist die Anmeldung gesperrt: " + $blockedHosts.SessionHost}

# XML Ausgabe für PRTG
"<?xml version=""1.0"" encoding=""UTF-8"" ?>"
"<prtg>"
"<result>" 
"<channel>Gesperrte Sessionhosts</channel>" 
"<value>"+$blockedHosts.Count+"</value>"
"</result>"
"<result>"
"<channel>Anzahl der Sessionhosts in der Sammlung</channel>"    
"<value>"+$SessionHost.Count+"</value>"
"</result>"
"<text>" + $OutputText +"</text>"
"</prtg>"