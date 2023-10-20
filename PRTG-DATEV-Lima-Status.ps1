# PRTG-Skript zum pruefen des DATEV Lima-Status
# Stannek GmbH - E.Sauerbier - v.2.5 - 20.10.2023

# Servername fuer den PRTG-Sensor, falls der Lima nicht auf der PRTG-Probe laeuft
param([string]$LiMaServer = "$env:COMPUTERNAME")

# Pfad zum DATEV LimaStatus-Tool
$PathLimaStatusTool = Join-Path -Path $Env:DATEVPP -ChildPath "\PROGRAMM\Sws\LiMaStatus.exe"

# DATEV Tool LiMaStatus entsprechend starten
If (Test-Path $PathLimaStatusTool) 
{
$Process = Start-Process -FilePath $PathLimaStatusTool -NoNewWindow -Wait -PassThru
}
Else {
# Falls der Lima nicht an der PRTG-Probe laeuft, wird eine Remote-Aufruf durchgefuehrt
$Process = Invoke-Command -cn $LiMaServer -ScriptBlock {param($PathLimaStatusTool=$PathLimaStatusTool)
            $result = Start-Process -FilePath $PathLimaStatusTool -NoNewWindow -Wait -PassThru
            New-Object -TypeName PSCustomObject -Property @{Exitcode=$result.ExitCode}
           } -ArgumentList $PathLimaStatusTool
}

# Ergebnis des DATEV Tools auswerten
if ($Process.ExitCode -eq $Null ) {$TextPRTGSensor= "Fehler beim Aufruf vom Tool (LiMaStatus.exe) auf folgendem Server: $LiMaServer";$ExitCodeLima = "5"}
if ($Process.ExitCode -eq "4" ) {$TextPRTGSensor= "POOL_INKONSISTENT";$ExitCodeLima = "4"}
if ($Process.ExitCode -eq "3" ) {$TextPRTGSensor= "Falsche DLL";$ExitCodeLima = "3"}
if ($Process.ExitCode -eq "2" ) {$TextPRTGSensor= "Falscher Parameter";$ExitCodeLima = "2"}
if ($Process.ExitCode -eq "1" ) {$TextPRTGSensor= "Lima Gestoppt";$ExitCodeLima = "1"}
if ($Process.ExitCode -eq "0" ) {$TextPRTGSensor= "Lima-Status OK";$ExitCodeLima = "0"}


# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Lima-Status</channel>`n" 
$OutputStringXML += "<value>"+ $ExitCodeLima +"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>" + $TextPRTGSensor  + "</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML