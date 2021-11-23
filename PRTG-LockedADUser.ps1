# Dieses PRTG-Skript prüft ob ein AD-Benutzer gesperrt ist
# Stannek GmbH - E.Sauerbier - v.1.1 - 23.11.2021

# AD-Modul importieren
Import-Module ActiveDirectory -ErrorAction Stop

# AD-Abfrage
$LockedUser=Search-ADAccount -LockedOut -UsersOnly | Select-Object -ExpandProperty SamAccountName

If ($LockedUser -eq $Null) {$Prtgtext = "OK"}
Else {$Prtgtext = "Folgende Benutzer sind gesperrt: " + $LockedUser}

# Ausgabe für PRTG
"<prtg>"
"<result>" 
"<channel>Locked Users</channel>" 
"<value>"+ $LockedUser.Count +"</value>" 
"</result>"
"<text>" + $PRTGtext  + "</text>"
"</prtg>"