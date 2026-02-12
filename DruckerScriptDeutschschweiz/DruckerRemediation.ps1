# =========================
# Intune Proactive Remediation - REMEDIATION
# - Loescht alle TCP/IP-Drucker und -Ports mit Portname/Portname=IPv4
# - Legt definierte Drucker/Ports neu an (RAW 9100)
# - Bricht ab, wenn kein passender Ricoh/PCL6 Treiber gefunden wird
# Exit 0 = Erfolg, Exit 1 = Fehler (Intune markiert Remediation als failed)
# =========================

$ErrorActionPreference = "Stop"

# Ricoh Treibername (Fallbacks)
$PreferredDriverName = "PCL6 Driver for Universal Print"
$DriverCandidates = @(
    $PreferredDriverName,
    "RICOH PCL6 UniversalDriver V4.42"
)

# Drucker (hardcodiert)
$Printers = @(
    @{ Name = "PRN-ALT-105"; IP = "10.252.9.41" }
    @{ Name = "PRN-ALT-104"; IP = "10.252.9.43" }
    @{ Name = "PRN-ALT-208"; IP = "10.252.9.44" }
    @{ Name = "PRN-ALT-207"; IP = "10.252.9.72" }
    @{ Name = "PRN-ALT-LZ"; IP = "10.252.9.102" }

    @{ Name = "PRN-LIM-LZ"; IP = "10.252.9.197" }
    @{ Name = "PRN-LIM-CAFFE"; IP = "10.252.9.235" }
    @{ Name = "PRN-LIM-401"; IP = "10.252.9.236" }
    @{ Name = "PRN-LIM-302"; IP = "10.252.9.210" }
    @{ Name = "PRN-LIM-307"; IP = "10.252.9.215" }

    @{ Name = "PRN-OER-1001"; IP = "10.252.10.17" }
    @{ Name = "PRN-OER-LZ-RECHTS"; IP = "10.252.10.58" }
    @{ Name = "PRN-OER-505"; IP = "10.252.10.87" }
    @{ Name = "PRN-OER-LZ-LINKS"; IP = "10.252.10.110" }

    @{ Name = "PRN-RAP-08"; IP = "10.252.8.59" }
    @{ Name = "PRN-RAP-09"; IP = "10.252.8.72" }
    @{ Name = "PRN-RAP-LZ"; IP = "10.252.8.103" }

    @{ Name = "PRN-AAR-206"; IP = "10.252.0.21" }
    @{ Name = "PRN-WL7-512"; IP = "10.252.2.165" }
    @{ Name = "PRN-WL7-552"; IP = "10.252.2.144" }
    @{ Name = "PRN-WL7-LZ"; IP = "10.252.2.240" }
    @{ Name = "PRN-BAS-LZ"; IP = "10.252.1.199" }

    @{ Name = "PRN-LUS-LZ"; IP = "10.252.5.135" }
    @{ Name = "PRN-LUS-3OG-GANG"; IP = "10.252.5.134" }
    @{ Name = "PRN-LUT-LZ-TÖ3"; IP = "10.205.167.20" }
    @{ Name = "PRN-ZUG-LZ"; IP = "10.252.11.14" }
    @{ Name = "PRN-ZUG-103"; IP = "10.252.11.13" }
    @{ Name = "PRN-ZUG-101"; IP = "10.252.11.15" }
)

# --- Treiber finden (erst exakte Kandidaten, dann Ricoh+PCL6 Fallback) ---
$InstalledDrivers = Get-PrinterDriver

$Driver = $InstalledDrivers | Where-Object { $DriverCandidates -contains $_.Name } | Select-Object -First 1
if (-not $Driver) {
    $Driver = $InstalledDrivers | Where-Object { $_.Name -match "Ricoh" -and $_.Name -match "PCL6" } | Select-Object -First 1
}

if (-not $Driver) {
    Write-Output "Kein geeigneter Ricoh/PCL6 Treiber gefunden - Abbruch."
    exit 1
}

$DriverName = $Driver.Name
Write-Output "Verwende Treiber: $DriverName"

# --- 1) Alle vorhandenen TCP/IP-Drucker entfernen (wie Original: PortName=IPv4) ---
Get-Printer | Where-Object {
    $_.PortName -match '^\d{1,3}(\.\d{1,3}){3}$'
} | ForEach-Object {
    Remove-Printer -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
}

# --- 2) Alle TCP/IP-Ports entfernen (wie Original: Name=IPv4) ---
Get-PrinterPort | Where-Object {
    $_.Name -match '^\d{1,3}(\.\d{1,3}){3}$'
} | ForEach-Object {
    Remove-PrinterPort -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
}

# --- 3) Drucker hinzufügen (wie Original) ---
foreach ($printer in $Printers) {
    $Name = $printer.Name
    $IP   = $printer.IP

    if (-not (Get-PrinterPort -Name $IP -ErrorAction SilentlyContinue)) {
        Add-PrinterPort -Name $IP -PrinterHostAddress $IP -PortNumber 9100
    }

    # Falls der Name schon existiert (z.B. anderer Port), entfernen und neu anlegen
    $existing = Get-Printer -Name $Name -ErrorAction SilentlyContinue
    if ($existing) {
        Remove-Printer -Name $Name -Confirm:$false -ErrorAction SilentlyContinue
    }

    Add-Printer -Name $Name -PortName $IP -DriverName $DriverName
}

exit 0
