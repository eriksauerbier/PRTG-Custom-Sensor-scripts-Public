# PRTG-Skript zum Abfragen von vorhandenen Snaptshot auf einem Hyper-V Host
# Stannek GmbH - v.1.2 - 07.11.2023 - E.Sauerbier


# Parameter für den PRTG-Sensor
param([string]$HyperVHost = " ",[string]$Password = ' ',$Admin = " ")

$PSSCred = New-Object System.Management.Automation.PSCredential -ArgumentList $Admin,$(ConvertTo-SecureString -AsPlainText $Password -Force)

# Alle Virtuelle Maschinen am Host nach Snapshots abfragen
$SnapShots = Invoke-Command -ComputerName $HyperVHost -Credential $PSSCred -ErrorVariable ConnectError -ScriptBlock {Get-VM | Get-VMSnapshot | Select-Object VMName,Name,SnapshotType,CreationTime,ComputerName}

# Anzahl der Snapshots in PRTG Value schreiben
$PRTGValue = $SnapShots.VMName.Count

# Ausgabe-Text generieren
If ($Null -eq $SnapShots) {$TextPRTGSensor = "Es befinden sich keine Snapshots auf dem Host"}
Else {$TextPRTGSensor = "Folgende VM(s) hat/haben Snapshot(s): $($SnapShots.VMName)"}

# Fehlerbehandlung
If ($ConnectError -ne $Null) {$TextPRTGSensor = "Es ist ein Fehler bei der VM-Abfrage aufgetreten";$PRTGValue="1"}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Snapshots</channel>`n" 
$OutputStringXML += "<value>"+$PRTGValue+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML