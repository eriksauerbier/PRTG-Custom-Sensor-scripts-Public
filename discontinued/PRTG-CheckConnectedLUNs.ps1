# Dieses PRTG-Skript prüft wieviele LUNs pro Hyper-V Host an jedem ClusterNode verbunden sind und schlägt bei ungleichheit an
# Stannek GmbH - E.Sauerbier - v.1.2 - 07.11.2023

# Parameter für den PRTG-Sensor (ClusterNode auf dem das Skript ausgeführt wird und ClusterName
param([string]$VMHost = "N/A",[string]$Cluster = "N/A",[string]$Password = ' ',$Admin = " ",[string]$Domain = ' ')

# Fehlervariable zurücksetzen
$failureHost = $null

# Credentials für PSRemote-Befehl erstellen
$PSCred = New-Object System.Management.Automation.PSCredential -ArgumentList $Admin,(ConvertTo-SecureString -AsPlainText $Password -Force)

# ClusterNodes abfragen
$ClusterNodes = Invoke-Command -ComputerName $VMHost -Credential $PSCred -ScriptBlock {
$ClusterNodes = Get-ClusterNode | Select-Object -ExpandProperty Name
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
$ClusterNode = $ClusterNode + "." + $Domain
$LunCount = invoke-command -computername $ClusterNode -scriptblock {
$Luns = (Get-WmiObjec -Namespace root\wmi -Class mpio_disk_info).driveinfo | Select-Object Name
$Luns.Count
}
# Wenn die verbundenen LUNs abweichen, dann wird der betroffenen Host in eine Fehler-Variable geschrieben
If ($LUNCompareValue -ne $LunCount) {$failureHost += @($ClusterNode)}
}

# Ausgabe-Text generieren
If ($failureHost.count -eq "0") {$TextPRTGSensor = "Die MPIO-LUN Verbindungen sind OK"}
Else {$TextPRTGSensor = "An " + $failureHost.count + " Hosts passen die MPIO-LUN Verbindungen nicht ("+$failureHost+")"}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Host mit fehlerhafter LUN-Verbindung</channel>`n" 
$OutputStringXML += "<value>"+$failureHost.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML