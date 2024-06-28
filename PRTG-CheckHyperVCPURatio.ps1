# Dieses PRTG-Skript zum auslesen des CPU Ueberbuchungsfaktors.
# Stannek GmbH - E.Sauerbier - v.1.5 - 28.06.2024

# Parameter fuer den PRTG-Sensor
param([string]$HyperVHost = "",[string]$Password = '',$Admin = "")

## Funktionen laden

# Funktion zum auslesen der Hyper-V Host Infos. Written by Haiko Hertes | www.hertes.net
function Get-HyperVHostInfo()
{   $VMs = Get-VM -ComputerName $env:COMPUTERNAME
    $vCores = (($VMs | Where-Object State -ne Off).ProcessorCount | Measure-Object -Sum).Sum
    $VMCount = $VMs.Count
    $VMCountRun = ($VMs | Where-Object State -ne Off).Count
    $Property = '"numberOfCores", "NumberOfLogicalProcessors"'
    $CPUs = Get-Ciminstance -class Win32_Processor -Property "numberOfCores", "NumberOfLogicalProcessors" | Select-Object -Property "numberOfCores", "NumberOfLogicalProcessors"
    $Cores = ($CPUs.numberOfCores | Measure-Object -Sum).Sum
    $logCores = ($CPUs.NumberOfLogicalProcessors | Measure-Object -Sum).Sum

    $os = Get-Ciminstance Win32_OperatingSystem
    $MemFreePct = [math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,2)

    $object = New-Object -TypeName PSObject
    $object | Add-Member –MemberType NoteProperty –Name PhysicalCores –Value $Cores
    $object | Add-Member –MemberType NoteProperty –Name LogicalCores –Value $logCores
    $object | Add-Member –MemberType NoteProperty –Name VirtualCores –Value $vCores
    $object | Add-Member –MemberType NoteProperty –Name MemTotalGB -Value ([int]($os.TotalVisibleMemorySize/1mb))
    $object | Add-Member –MemberType NoteProperty –Name MemFreeGB -Value ([math]::Round($os.FreePhysicalMemory/1mb,2))
    $object | Add-Member –MemberType NoteProperty –Name MemFreePct -Value $MemFreePct
    $object | Add-Member –MemberType NoteProperty –Name VMCount -Value $VMCount
    $object | Add-Member –MemberType NoteProperty –Name VMCountRunning -Value $VMCountRun

    Return $object
}

# Credentials fuer PSRemote-Befehl erstellen
$PSSCred = New-Object System.Management.Automation.PSCredential -ArgumentList $Admin,(ConvertTo-SecureString -AsPlainText $Password -Force)

# Hyper-V Host Info auf dem Hyper-V Host abfragen
$HostData = Invoke-Command -ComputerName $HyperVHost -Credential $PSSCred -ErrorVariable ConnectError -ScriptBlock ${function:Get-HyperVHostInfo}

# Ueberbuchungsfaktor errechnen
$CPURatio = $([math]::Round(($Hostdata.VirtualCores) /  ($Hostdata.PhysicalCores),2))
$logCPURatio = $([math]::Round(($Hostdata.VirtualCores) /  ($Hostdata.LogicalCores),2))

# Ausgabe-Text generieren
If ($ConnectError.Count -ne 0) {$TextPRTGSensor = "Es ist ein Fehler bei der VM-Abfrage aufgetreten";$CPURatio="0"}
Else {$TextPRTGSensor = "Der Host hat einen logischen Ueberbuchungsfaktor von 1 zu $logCPURatio"}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Physikalische Kerne</channel>`n" 
$OutputStringXML += "<value>"+$($Hostdata.PhysicalCores)+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Logische Kerne</channel>`n" 
$OutputStringXML += "<value>"+$($Hostdata.LogicalCores)+"</value>`n"
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>virtuelle Kerne</channel>`n"
$OutputStringXML += "<value>"+$Hostdata.VirtualCores+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Core:vCore Faktor</channel>`n"
$OutputStringXML += "<value>"+$CPURatio+"</value>`n" 
$OutputStringXML += "<Float>1</Float>`n"
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>LogicalCore:vCore Faktor (1 zu X)</channel>`n"
$OutputStringXML += "<value>"+$logCPURatio+"</value>`n" 
$OutputStringXML += "<Float>1</Float>`n"
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Anzahl VM</channel>`n"
$OutputStringXML += "<value>"+$($Hostdata.VMCount)+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<channel>Anzahl VM (Laufend)</channel>`n"
$OutputStringXML += "<value>"+$($Hostdata.VMCountRunning)+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>" + $TextPRTGSensor  + "</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML