# PRTG-Skript zum Abfragen von vorhandenen Snaptshot auf einem Hyper-V Host
# Stannek GmbH - v.1.0 - 30.05.2022 - E.Sauerbier


# Parameter für den PRTG-Sensor
param([string]$HyperVHost = " ",[string]$Password = ' ',$Admin = " ")

$PSSCred = New-Object System.Management.Automation.PSCredential -ArgumentList $Admin,(ConvertTo-SecureString -AsPlainText $Password -Force)

# Alle VirtuelleMaschinen am Host nach Snapshots abfragen
$SnapShots = Invoke-Command -ComputerName $HyperVHost -Credential $PSSCred -ErrorVariable ConnectError -ScriptBlock {Get-VM | Get-VMSnapshot | Select-Object VMName,Name,SnapshotType,CreationTime,ComputerName}

# Anzahl der Snapshots in PRTG Value schreiben
$PRTGValue = $SnapShots.VMName.Count

# Ausgabe-Text generieren
If ($SnapShots -eq $Null) {$OutPutText = "Es befinden sich keine Snapshots auf dem Host"}
Else {$OutPutText = "Folgende VM(s) hat/haben Snapshot(s): $($SnapShots.VMName)"}

# Fehlerbehandlung
If ($ConnectError -ne $Null) {$OutPutText = "Es ist ein Fehler bei der VM-Abfrage aufgetreten";$PRTGValue="1"}

# Ausgabe für PRTG
"<prtg>"
"<result>" 
"<channel>Snapshots</channel>"    
"<value>$PRTGValue</value>" 
"</result>"
"<text>$Outputtext</text>"
"</prtg>"