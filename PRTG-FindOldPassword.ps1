# Dieses PRTG-Skript sucht nach nicht geänderten Userpasswörtern entsprechend der Passwortrichtlinien des Kundens.
# Stannek GmbH - E.Sauerbier - v.1.2 - 07.11.2023

# Parameter für den PRTG-Sensor
param([string]$sincedays = "0",[string]$searchbase1 = " ",[string]$searchbase2 = " ")

# Searchbase im Format OU=Users,DC=Domain,DC=local


# Datum für die aktuelle Abfrage errechnen (Heute - $sincedays)
$searchdate =  Get-Date -format yyyy-MM-dd ((Get-Date).addDays(-$sincedays))  
$passwordsNotChangedSince = $([datetime]::parseexact($searchdate,'yyyy-MM-dd',$null)).ToFileTime()  

If ($searchbase1 -ne " ") {
# Suche für Searchbase1  
$Query1 = Get-ADUser -filter { Enabled -eq $True } –Properties PwdLastSet -searchbase $searchbase1 -ErrorVariable failure | Where-Object { $_.pwdLastSet -lt $passwordsNotChangedSince -and $_.pwdLastSet -ne 0 } |  Select-Object sAmAccountName  
}
         
# Suche für Searchbase2
If ($searchbase2 -ne " ") {
$Query2 = Get-ADUser -filter { Enabled -eq $True } –Properties PwdLastSet -searchbase $searchbase2 -ErrorVariable failure | Where-Object { $_.pwdLastSet -lt $passwordsNotChangedSince -and $_.pwdLastSet -ne 0 } |  Select-Object sAmAccountName  
}

# Werte für die Ausgabe generieren
$Oldpasswords = $Query1.Count + $Query2.Count
$Users = $Query1.sAmAccountName + $Query2.sAmAccountName
If ($Oldpasswords -ne "0") {$TextPRTGSensor = "Folgende User haben Ihr Kennwort seit mehr als $sincedays Tagen nicht geaendert: $Users"}
Else {$TextPRTGSensor = "Alle Benutzer habe Ihr Kennwort vor $sincedays Tagen geaendert"}

# Fehlerabfrage
If ($failure -ne $Null) {$Oldpasswords = "1"; $Users = "Es ist ein Fehler aufgetreten"}
Else {If (($Query1 -eq " ") -and ($Query2 -eq " ")) {$Oldpasswords = "1"; $Users = "Es ist ein Fehler aufgetreten"}}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Passwort zu alt</channel>`n" 
$OutputStringXML += "<value>"+$Oldpasswords+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>"+$TextPRTGSensor+"</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML