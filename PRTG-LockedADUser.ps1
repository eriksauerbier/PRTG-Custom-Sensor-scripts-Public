# Dieses PRTG-Skript prueft ob ein AD-Benutzer gesperrt ist
# Stannek GmbH - E.Sauerbier - v.1.5 - 20.10.2023

# AD-Modul importieren
Import-Module ActiveDirectory -ErrorAction Stop

# AD-Abfrage
$LockedUser=Search-ADAccount -LockedOut -UsersOnly | Select-Object -ExpandProperty SamAccountName

# Sensortext festlegen
If ($Null -eq $LockedUser) {$TextPRTGSensor = "Es sind keine AD-Benutzer gesperrt"}
Else {$TextPRTGSensor = "Folgende AD-Benutzer sind gesperrt: " + $LockedUser}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Locked Users</channel>`n" 
$OutputStringXML += "<value>"+ $LockedUser.Count +"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>" + $TextPRTGSensor  + "</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML