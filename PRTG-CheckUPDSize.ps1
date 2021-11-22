# PRTG-Skript zum täglichen prüfen der FSLogix UserProfileDisks Größe
# Stannek GmbH - Version 1.00 - 23.06.2021 ES

# Parameter angeben

$FSLogixPolicyName = "FSLogixConfig"

# weitere Parameter aus der FSLogix-GPO ermitteln

$FSLogixgpo = Get-GPO -Name $FSLogixPolicyName
$UPDSize = Get-GPRegistryValue -Guid $FSLogixgpo.Id -Key "HKLM\Software\FSLogix\Profiles" -ValueName "SizeInMBs" | Select -ExpandProperty Value
# Warnschwelle festlegen (15% Restgröße)
$UPDCompareSize = $UPDSize - ($UPDSize * 0.15)
$FslogixDir = Get-GPRegistryValue -Guid $FSLogixgpo.Id -Key "HKLM\Software\FSLogix\Profiles" -ValueName "VHDLocations" | Select -ExpandProperty Value
$FslogixDir = $FslogixDir -Replace ("`0","") # Entfernt ASCII NUL-Charakter, da dies für gci Problematisch ist
$VolumeType = Get-GPRegistryValue -Guid $FSLogixgpo.Id -Key "HKLM\Software\FSLogix\Profiles" -ValueName "VolumeType" | Select -ExpandProperty Value
$fileextension = "*." + $VolumeType
$fileextension = $fileextension -Replace ("`0","") # Entfernt ASCII NUL-Charakter, da dies für gci Problematisch ist

# Größe der UPDs ermitteln

$vhdxsize = gci $FslogixDir $fileextension -recurse | Select-Object Name, @{Name="Size";Expression={[Math]::round($_.length / 1MB, 2)}}

# Vergleich der einzelnen UPDs
foreach ($compare in $vhdxsize) {
if ($compare.Size -ge $UPDCompareSize) 
    {
    $CriticalUDPSize = $compare
    }
}

# Ausgabe für PRTG
"<?xml version=""1.0"" encoding=""UTF-8"" ?>"
"<prtg>"
"<result>" 
"<channel>Total ProfileDisks</channel>" 
"<value>"+$vhdxsize.Count+"</value>"
"</result>"
"<result>" 
"<channel>Max UPD Size</channel>" 
"<value>"+$UPDSize+"</value>"
"<Unit>Custom</Unit>"
"<CustomUnit>MB</CustomUnit>"
"</result>"
"<result>"
"<channel>Critical UPD Size</channel>"
 "<value>"+$CriticalUDPSize.Count+"</value>"
"</result>"
"</prtg>"