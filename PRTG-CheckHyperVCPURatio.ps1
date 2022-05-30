# Dieses PRTG-Skript liest den CPU Überbuchungsfaktor eines Hyper-V Hosts aus
# Stannek GmbH - E.Sauerbier - v.1.01 - 30.05.2022

# Parameter für den PRTG-Sensor
param([string]$HyperVHost = "")

## Funktionen laden

# Funktion zum auslesen der Hyper-V Host Infos. Written by Haiko Hertes | www.hertes.net
function Get-HyperVHostInfo()
{   $vCores = ((Get-VM -ComputerName $env:COMPUTERNAME).ProcessorCount | Measure-Object -Sum).Sum

    $Property = "numberOfCores", "NumberOfLogicalProcessors"
    $CPUs = Get-Ciminstance -class Win32_Processor -Property  $Property -ComputerName $env:COMPUTERNAME| Select-Object -Property $Property 
    $Cores = ($CPUs.numberOfCores | Measure-Object -Sum).Sum
    $logCores = ($CPUs.NumberOfLogicalProcessors | Measure-Object -Sum).Sum

    $os = Get-Ciminstance Win32_OperatingSystem -ComputerName $env:COMPUTERNAME
    $MemFreePct = [math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,2)

    $object = New-Object -TypeName PSObject
    $object | Add-Member –MemberType NoteProperty –Name PhysicalCores –Value $Cores
    $object | Add-Member –MemberType NoteProperty –Name LogicalCores –Value $logCores
    $object | Add-Member –MemberType NoteProperty –Name VirtualCores –Value $vCores
    $object | Add-Member –MemberType NoteProperty –Name MemTotalGB -Value ([int]($os.TotalVisibleMemorySize/1mb))
    $object | Add-Member –MemberType NoteProperty –Name MemFreeGB -Value ([math]::Round($os.FreePhysicalMemory/1mb,2))
    $object | Add-Member –MemberType NoteProperty –Name MemFreePct -Value $MemFreePct

    Return $object
}

# Hyper-V Host Info auf dem Hyper-V Host abfragen
$HostData = Invoke-Command -ComputerName $HyperVHost -ScriptBlock ${function:Get-HyperVHostInfo}

# Überbuchungsfaktor errechnen
$CPURatio = $([math]::Round(($Hostdata.VirtualCores) /  ($Hostdata.PhysicalCores),2))
$logCPURatio = $([math]::Round(($Hostdata.VirtualCores) /  ($Hostdata.LogicalCores),2))

# XML Ausgabe für PRTG erzeugen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$output = @"

<?xml version=`"1.0`" encoding=`"UTF-8`" ?>
<prtg>
<result>
<channel>Physikalische Kerne</channel>
<value>$($Hostdata.PhysicalCores)</value>
</result>
<result>
<channel>Logische Kerne</channel>
<value>$($Hostdata.LogicalCores)</value>
</result>
<result>
<channel>virtuelle Kerne</channel>
<value>$($Hostdata.VirtualCores)</value>
</result>
<result>
<channel>Core:vCore Faktor</channel>
<value>$CPURatio</value>
<Float>1</Float>
</result>
<result>
<channel>LogicalCore:vCore Faktor (1 zu X)</channel>
<value>$logCPURatio</value>
<Float>1</Float>
</result>
<text>Der Host hat einen logischen Überbuchungsfaktor von 1 zu $logCPURatio </text>
</prtg>
"@

[Console]::WriteLine($output)