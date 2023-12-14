# Dieses PRTG-Skript sucht nach Zertifikaten die in X-Tagen ablaufen
# Stannek GmbH - E.Sauerbier - v.1.6 - 14.12.2023

# Servername für PRTG-Sensor, falls der Cert-Server nicht auf der PRTG-Probe läuft
param([string]$NameServer="",[string]$PathCerts="Cert:\LocalMachine\MY",[string]$sincedays="31")

# Beschreibung
# $NameServer = Hier den Servernamen angeben
# $sincedays = Dies ist die Warnschwelle in Tagen angeben
# $PathCerts = Dies ist der lokale Zertifkatspfad im Format "Cert:\LocalMachine\"

# Datum für die aktuelle Abfrage errechnen (Heute - $sincedays)
$searchdate =  Get-Date -format yyyy-MM-dd ((Get-Date).addDays($sincedays))  

# Remote-Abfrage der Ablaufdaten der Zertifikate im Zertifikatsspeicher
$expiringCerts = Try {Invoke-Command -cn $NameServer -ScriptBlock { param($PathCerts,$searchdate)
get-childitem -Recurse $PathCerts | Where-Object {$_.NotAfter -lt $searchdate} | Select-Object -ExpandProperty Subject
} -ArgumentList $PathCerts,$searchdate -ErrorAction Stop}
Catch {"Fehler"}

# Wert frü PRTG-Sensor erzeugen
$prtgvalue = "0"
If ($expiringCerts -eq "Fehler") {$prtgvalue = 999;}
Elseif ($expiringCerts.Count -ge 1) {$prtgvalue = $expiringCerts.Count}
Elseif ($expiringCerts.Count -eq 0) {$expiringCerts = "Keine"}

# Text für Sensor erzeugen
If ($expiringCerts -eq "Fehler") {$TextPRTGSensor = "Fehler bei der Server-Abfrage"}
ElseIf ($expiringCerts -eq "Keine") {$TextPRTGSensor = "Keine Zertifikat laufen in weniger als $sincedays Tagen ab"}
Else {$TextPRTGSensor = "Folgende Zertifikat laufen in weniger als $sincedays Tagen ab: $expiringCerts"}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>expiring Certificates</channel>`n" 
$OutputStringXML += "<value>"+$prtgvalue+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML
