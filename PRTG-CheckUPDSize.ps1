# PRTG-Skript zum taeglichen pruefen der FSLogix UserProfileDisks Groesse
# Stannek GmbH - Version 2.0 - 20.10.2023 ES

# Parameter angeben
$NameGPOFSLogix = "FSLogixConfig"

# weitere Parameter aus der FSLogix-GPO ermitteln
$GPOFSLogix = Get-GPO -Name $NameGPOFSLogix
$SizePolicyUPD = Get-GPRegistryValue -Guid $GPOFSLogix.Id -Key "HKLM\Software\FSLogix\Profiles" -ValueName "SizeInMBs" | Select -ExpandProperty Value
# Warnschwelle festlegen (15% Restgröße)
$SizeCompareUPD = $SizePolicyUPD - ($SizePolicyUPD * 0.15)
$PathUPD = Get-GPRegistryValue -Guid $GPOFSLogix.Id -Key "HKLM\Software\FSLogix\Profiles" -ValueName "VHDLocations" | Select -ExpandProperty Value
$PathUPD = $PathUPD -Replace ("`0","") # Entfernt ASCII NUL-Charakter, da dies fuer gci Problematisch ist
$VolumeType = Get-GPRegistryValue -Guid $GPOFSLogix.Id -Key "HKLM\Software\FSLogix\Profiles" -ValueName "VolumeType" | Select -ExpandProperty Value
$FileExtension = "*." + $VolumeType
$FileExtension = $FileExtension -Replace ("`0","") # Entfernt ASCII NUL-Charakter, da dies fuer Get-Childitem Problematisch ist

# Größe der UPDs ermitteln
$SizeUPDs = Get-ChildItem -Path $PathUPD -Filter $FileExtension -recurse | Select-Object Name, @{Name="Size";Expression={[Math]::round($_.length / 1MB, 2)}}

# Vergleich der einzelnen UPDs
foreach ($SizeUPD in $SizeUPDs) {
if ($SizeUPD.Size -ge $SizeCompareUPD) 
    {
    $CriticalSizeUPD += @($SizeUPD)
    }
}

# Sensortext festlegen
If ($Null -eq $CriticalSizeUPD) {$TextPRTGSensor = "Alle UserProfileDisks sind kleiner als der Schwellwert"}
Else {$TextPRTGSensor = "Folgende UserProfileDisk(s) sind groesser als der Schwellwert: " + $CriticalSizeUPD.Name}

# Ausgabe-Variable fuer PRTG erzeugen
$OutputStringXML = "<?xml version=`"1.0`"?>`n"
$OutputStringXML += "<prtg>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Total ProfileDisks</channel>`n" 
$OutputStringXML += "<value>"+$SizeUPDs.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Max UPD Size</channel>`n" 
$OutputStringXML += "<value>"+$SizePolicyUPD+"</value>`n"
$OutputStringXML += "<Unit>Custom</Unit>`n"
$OutputStringXML += "<CustomUnit>MB</CustomUnit>`n"
$OutputStringXML += "</result>`n"
$OutputStringXML += "<result>`n" 
$OutputStringXML += "<channel>Critical UPD Size</channel>`n"
$OutputStringXML += "<value>"+$CriticalSizeUPD.Count+"</value>`n" 
$OutputStringXML += "</result>`n"
$OutputStringXML += "<text>" + $TextPRTGSensor  + "</text>`n"
$OutputStringXML += "</prtg>"

# Ausgabe fuer PRTG
Write-Output -InputObject $OutputStringXML