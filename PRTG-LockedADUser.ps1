# Dieses PRTG-Skript prüft ob ein AD-Benutzer gesperrt ist
# Stannek GmbH - E.Sauerbier - v.1.2 - 02.08.2022

# Parameter für den PRTG-Sensor
param([string]$DC = "")

if ($DC -eq "") {$LockedUser=Search-ADAccount -LockedOut -UsersOnly | Select-Object -ExpandProperty SamAccountName}
Else {$LockedUser = Invoke-Command -ComputerName $DC -ScriptBlock {Search-ADAccount -LockedOut -UsersOnly | Select-Object -ExpandProperty SamAccountName}}

# Ausgabetext generieren
If ($LockedUser -eq $Null) {$Prtgtext = "Keine Benutzer gesperrt"}
Else {$Prtgtext = "Folgende Benutzer sind gesperrt: " + $LockedUser}

# Ausgabe für PRTG
"<prtg>"
"<result>" 
"<channel>Locked Users</channel>" 
"<value>"+ $LockedUser.Count +"</value>" 
"</result>"
"<text>" + $PRTGtext  + "</text>"
"</prtg>"