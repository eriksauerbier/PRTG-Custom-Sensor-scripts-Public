# Skript zum Vergleich der Cluster-VMs und der in VeeamBackupJobs befindlichen Cluster-VMs
# Stannek GmbH - v.1.1 - 12.05.2022 - E.Sauerbier

# Parameter für den PRTG-Sensor
param([string]$remoteserver = "N/A")

# PS-Session am Backup-Server öffnen
invoke-command -computername $remoteserver -scriptblock {

# Veeam PS-Snapin laden
Add-PSSnapin VeeamPSSnapin

# Aktive Veeam VM Backup-Jobs auslesen
$Jobnames = Get-VBRJob | Where-Object {($_.JobType -eq "Backup") -and ($_.IsScheduleEnabled -eq "True")} | Select-Object Name

# VM-Namen der Backup-Jobs in Variable schreiben
$Jobobjects = foreach ($Jobname in $Jobnames) {Get-VBRJobObject -Job $Jobname.Name | Select Name}

# Cluster-VMs auslesen
$ClusterVM = Get-ClusterResource -Cluster RZCLuster | Where ResourceType -eq "Virtual Machine" | Select OwnerGroup

# Namen der Cluster-VMs in Variable schreiben
$NameClusterVM = $ClusterVM | ForEach-Object {$_.OwnerGroup}

# Vergleichen der Cluster-VMs und der in VeeamBackupJobs befindlichen Cluster-VMs
$output = Compare-Object -ReferenceObject $NameClusterVM.Name -DifferenceObject $Jobobjects.Name | Foreach-object InputObject

# XML Ausgabe für PRTG
#"<?xml version=`"1.0`" encoding=`"UTF-8`" ?>"
"<prtg>"
"<result>" 
"<channel>nicht gesicherte ClusterVMs</channel>"    
"<value>"+ $output.Count +"</value>" 
"</result>"
"<result>" 
"<channel>Anzahl Cluster VMs</channel>"    
"<value>"+ $ClusterVM.Count +"</value>" 
"</result>"
"<result>" 
"<channel>Anzahl VMs in Backupjobs</channel>"    
"<value>"+ $Jobobjects.Count +"</value>" 
"</result>"
"<text>Das Hyper-V Cluster hat"+$ClusterVM.Count+" VMs und davon werden "+ $Jobobjects.Count +" Cluster.VMs gesichert</text>"
"</prtg>"

}