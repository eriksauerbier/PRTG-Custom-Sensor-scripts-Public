# Dieses PRTG-Skript sucht nach Zertifikaten die in X-Tagen ablaufen
# Stannek GmbH - v.1.4 - E.Sauerbier 23.11.2021

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
gci -Recurse $CertPath | ?{$_.NotAfter -lt $searchdate} | select -ExpandProperty Subject
} -ArgumentList $CertPath,$searchdate -ErrorAction Stop


$prtgvalue = "0"
if ($expiredCert.Count -ge 1) {$prtgvalue = $expiredCert.Count}
if ($expiredCert.Count -eq 0) {$expiredCert = "Keine"}

$prtgtext = "Folgende Zertifikat laufen in weniger als $sincedays Tagen ab: $expiredCert"


# Ausgabe für PRTG
"<?xml version=`"1.0`" encoding=`"UTF-8`" ?>"
"<prtg>"
"<result>"
"<channel>Expired Certificate</channel>"
"<value>$prtgvalue</value>"
"</result>"
"<text>$prtgtext</text>"
"</prtg>"