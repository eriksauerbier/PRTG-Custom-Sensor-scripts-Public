# PRTG-Skript zum starten von 64Bit Powershell Skripts
# Stannek GmbH - v.1.0 - 30.05.2022 - E.Sauerbier

# Paramter die vom Sensor mit gegeben werden
param([string]$ScriptPath = $Null,[string]$ScriptName = " ")

# Parameter
$PRTGPRobeScriptPath = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\"

# Wenn kein Skriptpfad mitgegeben wurde, dann wird der Standard PRTG-Skriptpfad genutzt
If (($ScriptPath -eq $Null) -or ($ScriptPath -eq "")) {$ScriptPath = $PRTGPRobeScriptPath}

# 64Bit Powershell mit dem entsprechenden Skript starten
c:\windows\Sysnative\windowspowershell\v1.0\powershell.exe -file ($ScriptPath + $ScriptName)