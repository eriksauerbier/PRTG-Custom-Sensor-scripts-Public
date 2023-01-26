# Skript zum Vergleich der Cluster-VMs und der in VeeamBackupJobs befindlichen Cluster-VMs
# Stannek GmbH - v.1.1.2 - 26.01.2023 - E.Sauerbier

# Parameter für den PRTG-Sensor
param([String]$remoteserver = "",[string]$User = "",[string]$Password = '')

# Skriptblock erstellen
$ScriptBlock = {
# Powershell Modul importieren
Import-Module Veeam.Backup.PowerShell

# Aktive Veeam VM Backup-Jobs auslesen
$Jobnames = Get-VBRJob | Where-Object {($_.JobType -eq "Backup") -and ($_.IsScheduleEnabled -eq "True")} | Select-Object Name

# VM-Namen der Backup-Jobs in Variable schreiben
$Jobobjects = foreach ($Jobname in $Jobnames) {Get-VBRJobObject -Job $Jobname.Name | Select Name}

# Cluster auslesen
$Cluster = Get-Cluster -Domain $env:UserDomain

# Cluster-VMs auslesen
$ClusterVM = Get-ClusterResource -Cluster $Cluster | Where ResourceType -eq "Virtual Machine" | Select OwnerGroup

# Namen der Cluster-VMs in Variable schreiben
$NameClusterVM = $ClusterVM | ForEach-Object {$_.OwnerGroup}

$object = New-Object -TypeName PSObject
$object | Add-Member –MemberType NoteProperty –Name ClusterVM –Value $NameClusterVM
$object | Add-Member –MemberType NoteProperty –Name CountClusterVM –Value $NameClusterVM.Count
$object | Add-Member –MemberType NoteProperty –Name JobVMs –Value $Jobobjects
$object | Add-Member –MemberType NoteProperty –Name CountJobVM –Value $Jobobjects.Count

return $object
}

# Skriptblock ausführen, je nach mitgegebene Parametern
If ($remoteserver -eq "") {$Output = Invoke-Command -ScriptBlock $ScriptBlock}
Else {$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $User,$(ConvertTo-SecureString -AsPlainText $Password -Force)
      $Output = Invoke-Command -ComputerName $remoteserver -Credential $Cred -ScriptBlock $ScriptBlock}

# Vergleichen der Cluster-VMs und der in VeeamBackupJobs befindlichen Cluster-VMs
$Compare = Compare-Object -ReferenceObject $Output.ClusterVM.Name -DifferenceObject $Output.JobVMs.Name | Foreach-object InputObject

# PRTG Ausgabetext generieren
If ($Compare.Count -eq "0") {$OutputText = "Das Hyper-V Cluster hat "+$Output.CountClusterVM+" VMs und davon werden "+ $Output.CountJobVM +" Cluster-VMs gesichert"}
Else {$OutputText = "Folgende VMs werden nicht gesichert: $($Compare)"}

# XML Ausgabe für PRTG
"<?xml version=`"1.0`" encoding=`"UTF-8`" ?>"
"<prtg>"
"<result>" 
"<channel>nicht gesicherte ClusterVMs</channel>"    
"<value>"+ $Compare.Count +"</value>" 
"</result>"
"<result>" 
"<channel>Anzahl Cluster VMs</channel>"    
"<value>"+ $Output.CountClusterVM +"</value>" 
"</result>"
"<result>" 
"<channel>Anzahl VMs in Backupjobs</channel>"    
"<value>"+ $Output.CountJobVM +"</value>" 
"</result>"
"<text>$OutputText</text>"
"</prtg>"