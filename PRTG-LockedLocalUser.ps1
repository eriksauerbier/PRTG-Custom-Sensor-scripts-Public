# Dieses PRTG-Skript pr�ft ob ein Lokaler Benutzer gesperrt ist
# Stannek GmbH - v.1.01 - E.Sauerbier 23.11.2021

# Lokale User Abfrage
$lockedAccounts = @(Get-WmiObject win32_useraccount -filter "LockOut=True")
$lockedAccounts.name


# Ausgabe f�r PRTG
"<prtg>"
"<result>" 
"<channel>Locked Users</channel>"    
"<value>"+ $lockedAccounts.count +"</value>" 
"</result>"
"<text>" + $lockedAccounts.name + "</text>"
"</prtg>"