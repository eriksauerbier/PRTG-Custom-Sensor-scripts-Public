# Dieses PRTG-Skript prüft wieviele LUNs pro Hyper-V Host an jedem ClusterNode verbunden sind und schlägt bei ungleichheit an
# Stannek GmbH - E.Sauerbier - v.1.01 - 23.11.2021

# Parameter für den PRTG-Sensor (ClusterNode auf dem das Skript ausgeführt wird und ClusterName
param([string]$VMHost = "N/A",[string]$Cluster = "N/A")

# Fehlervariable zurücksetzen
$failureHost = $null

# ClusterNodes abfragen
$ClusterNodes = Invoke-Command -cn $VMHost -ScriptBlock {
$ClusterNodes = Get-ClusterNode | select -ExpandProperty Name
return $ClusterNodes 
}

# Anzahl der ClusterDisk auslesen
$ClusterDisks = Get-CimInstance -Namespace Root\MSCluster -ClassName MSCluster_Resource -ComputerName $Cluster | ?{$_.Type -eq 'Physical Disk'}
# Vergleichswert für verbundene LUNs erstellen (Die Hosts zeigen per mpio immer eine Verbindung mehr an, daher  "+1")
$LUNCompareValue = $ClusterDisks.Count + "1"

# Schleife zur Abfrage der verbunden LUNs pro Host im Cluster
foreach ($ClusterNode in $ClusterNodes){
# HostName erfassen
# Anzahl der verbundenen LUNs auf dem Host in der Schleife erfassen
$ClusterNode = $ClusterNode + ".rzdom.local"
$LunCount = invoke-command -computername $ClusterNode -scriptblock {
$Luns = (gwmi -Namespace root\wmi -Class mpio_disk_info).driveinfo | Select-Object Name
$Luns.Count
}
# Wenn die verbundenen LUNs abweichen, dann wird der betroffenen Host in eine Fehler-Variable geschrieben
If ($LUNCompareValue -ne $LunCount) {$failureHost += @($ClusterNode)}
}

# Ausgabe für PRTG
"<prtg>"
"<result>" 
"<channel>Host mit fehlerhafter LUN-Verbindung</channel>"    
"<value>"+ $failureHost.Count +"</value>" 
"</result>"
"<text> An " + $failureHost.count + " Hosts passen die MPIO-LUN Verbindungen nicht ("+$failureHost+")</text>"
"</prtg>"