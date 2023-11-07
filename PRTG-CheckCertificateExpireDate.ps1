# Dieses PRTG-Skript sucht nach Zertifikaten die in X-Tagen ablaufen
# Stannek GmbH - E.Sauerbier - v.1.5 - 07.11.2023

# Servername für PRTG-Sensor, falls der Cert-Server nicht auf der PRTG-Probe läuft
param([string]$Server=$Null,[string]$CertPath="Cert:\LocalMachine\My",[string]$sincedays="31")

# Beschreibung
# $Server = Hier den Servernamen angeben
# $sincedays = Dies ist die Warnschwelle in Tagen angeben
# $CertPath = Dies ist der lokale Zertifkatspfad im Format "Cert:\LocalMachine\"

# Datum für die aktuelle Abfrage errechnen (Heute - $sincedays)
$searchdate =  Get-Date -format yyyy-MM-dd ((Get-Date).addDays($sincedays))  

# Remote-Abfrage der Ablaufdaten der Zertifikate im Zertifikatsspeicher
$expiredCert = Invoke-Command -cn $Server -ScriptBlock { param($CertPath,$searchdate)
get-childitem -Recurse $CertPath | ?{$_.NotAfter -lt $searchdate} | Select-Object -ExpandProperty Subject
} -ArgumentList $CertPath,$searchdate -ErrorAction Stop

# Wert frü PRTG-Sensor erzeugen
$prtgvalue = "0"
if ($expiredCert.Count -ge 1) {$prtgvalue = $expiredCert.Count}
if ($expiredCert.Count -eq 0) {$expiredCert = "Keine"}

# Text für Sensor erzeugen
$TextPRTGSensor = "Folgende Zertifikat laufen in weniger als $sincedays Tagen ab: $expiredCert"

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Expired Certificate</channel>`n" 
$OutputStringXML += "<value>"+$prtgvalue+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML
