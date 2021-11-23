# PRTG-Skript zum prüfen des DATEV Lima-Status
# Stannek GmbH - E.Sauerbier - v.2.04 - 23.11.2021

# Servername vom PRTG-Sensor, falls der Lima nicht auf der PRTG-Probe läuft
param([string]$LiMaServer = "N/A")

# Pfad zum DATEV LimaStatus-Tool

$PathLimaStatusTool = "\PROGRAMM\Sws\LiMaStatus.exe"
$LimaStatusTool = $Env:DATEVPP + $PathLimaStatusTool

# DATEV Tool LiMaStatus starten

If (Test-Path $LimaStatusTool) 
{
$process = Start-Process -FilePath $LimaStatusTool -NoNewWindow -Wait -PassThru
}
Else {
# Falls der Lima nicht an der PRTG-Probe läuft, wird eine Remote-Aufruf durchgeführt
$process = Invoke-Command -cn $LiMaServer -ScriptBlock {param($PathLimaStatusTool=$PathLimaStatusTool)
            $LimaStatusTool = $Env:DATEVPP + $PathLimaStatusTool
            $result = Start-Process -FilePath $LimaStatusTool -NoNewWindow -Wait -PassThru
            New-Object -TypeName PSCustomObject -Property @{Exitcode=$result.ExitCode}
           } -ArgumentList $PathLimaStatusTool
}

# Ergebnis des DATEV Tools auswerten
if ($process.ExitCode -eq $Null ) {$errormessage = "Fehler beim Aufruf vom Tool (LiMaStatus.exe) auf folgendem Server: $LiMaServer";$LASTEXITCODE = "5"}
if ($process.ExitCode -eq "4" ) {$errormessage = "POOL_INKONSISTENT";$LASTEXITCODE = "4"}
if ($process.ExitCode -eq "3" ) {$errormessage = "Falsche DLL";$LASTEXITCODE = "3"}
if ($process.ExitCode -eq "2" ) {$errormessage = "Falscher Parameter";$LASTEXITCODE = "2"}
if ($process.ExitCode -eq "1" ) {$errormessage = "Lima Gestoppt";$LASTEXITCODE = "1"}
if ($process.ExitCode -eq "0" ) {$errormessage = "Lima-Status OK";$LASTEXITCODE = "0"}

# XML Ausgabe für PRTG
"<prtg>"
"<result>"
"<channel>Lima-Status</channel>"
"<value>"+$LASTEXITCODE+"</value>"
"</result>"
"<text>$errormessage</text>"
"</prtg>"
