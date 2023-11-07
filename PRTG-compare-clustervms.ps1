# Skript zum Vergleich der Cluster-VMs und der in VeeamBackupJobs befindlichen Cluster-VMs
# Stannek GmbH - v.1.3 - 07.11.2023 - E.Sauerbier

# Parameter für den PRTG-Sensor
param([String]$remoteserver = "",[string]$User = "",[string]$Password = '')

# Skriptblock erstellen
$ScriptBlock = {
# Powershell Modul importieren
Import-Module Veeam.Backup.PowerShell

#Connect-VBRServer -Credential $Cred

# Aktive Veeam VM Backup-Jobs auslesen
$Jobnames = Get-VBRJob | Where-Object {($_.JobType -eq "Backup") -and ($_.IsScheduleEnabled -eq "True")} | Select-Object Name

# VM-Namen der Backup-Jobs in Variable schreiben und sortieren
$Jobobjects = foreach ($Jobname in $Jobnames) {Get-VBRJobObject -Job $Jobname.Name | Select Name}
$Jobobjects = $Jobobjects | Sort-Object Name

# Cluster auslesen
$Cluster = Get-Cluster -Domain $env:UserDomain

# Cluster-VMs auslesen
$ClusterVM = Get-ClusterResource -Cluster $Cluster | Where ResourceType -eq "Virtual Machine" | Select OwnerGroup

# Namen der Cluster-VMs in Variable schreiben
$NameClusterVM = $ClusterVM | ForEach-Object {$_.OwnerGroup}

$object = New-Object -TypeName PSObject
$object | Add-Member –MemberType NoteProperty –Name ClusterVM –Value $NameClusterVM
$object | Add-Member –MemberType NoteProperty –Name CountClusterVM –Value $NameClusterVM.Count
$object | Add-Member –MemberType NoteProperty –Name JobVMs –Value $($Jobobjects | Select-Object -ExpandProperty Name)
$object | Add-Member –MemberType NoteProperty –Name CountJobVM –Value $Jobobjects.Count

return $object
}

# Skriptblock ausführen, je nach mitgegebene Parametern
If ($remoteserver -eq "") {$Output = Invoke-Command -ScriptBlock $ScriptBlock}
Else {$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $User,$(ConvertTo-SecureString -AsPlainText $Password -Force)
      $Output = Invoke-Command -ComputerName $remoteserver -Credential $Cred -ScriptBlock $ScriptBlock}

# Vergleichen der Cluster-VMs und der in VeeamBackupJobs befindlichen Cluster-VMs
$Compare = Compare-Object -ReferenceObject $Output.ClusterVM.Name -DifferenceObject $Output.JobVMs

# Ausgabe generieren
$NoBackup = $Compare | Where-Object SideIndicator -eq "<=" | Select-Object -ExpandProperty InputObject 
$MultiBackup = $Compare | Where-Object SideIndicator -eq "=>" | Select-Object -ExpandProperty InputObject 

# PRTG Ausgabetext generieren
If ($Compare.InputObject.Count -eq "0") {$OutputText = "Das Hyper-V Cluster hat "+$Output.CountClusterVM+" VMs und davon werden "+ $Output.CountJobVM +" Cluster-VMs gesichert"}
Else {
    If ($Null -ne $NoBackup) {$TextPRTGSensor = "Folgende VMs werden nicht gesichert: $NoBackup"}
    Else {$TextPRTGSensor = "Folgende VMs werden mehrfach gesichert: $MultiBackup"}
    }

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Fehlerhafte VMs</channel>`n" 
$OutputStringXML += "<value>"+$Compare.InputObject.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Anzahl Cluster VMs</channel>`n" 
$OutputStringXML += "<value>"+$Output.CountClusterVM+"</value>`n"
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Anzahl VMs in Backupjobs</channel>`n"
$OutputStringXML += "<value>"+$Output.CountJobVM+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>" + $TextPRTGSensor  + "</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML