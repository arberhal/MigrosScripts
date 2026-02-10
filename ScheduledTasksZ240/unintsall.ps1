$TaskFolderName = "IT Education Services"
$TaskFolderPath = "\$TaskFolderName"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

$XmlDir = Join-Path $PackageRoot "ScheduledTasks"
$ScriptsDir = Join-Path $PackageRoot "Scripts"
$TargetScriptsDir = "C:\Scripts"

# 1) Tasks anhand der XMLs entfernen (kein Hardcoding)
if (Test-Path $XmlDir) {
    Get-ChildItem -Path $XmlDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
        $taskName = "$TaskFolderPath\$($_.BaseName)"
        schtasks /delete /tn $taskName /f *> $null
    }
}

# 2) Task-Ordner löschen (falls leer)
try {
    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect()
    $root = $service.GetFolder("\")
    $folder = $root.GetFolder($TaskFolderPath)

    if ($folder.GetTasks(0).Count -eq 0) {
        $root.DeleteFolder($TaskFolderPath, 0)
    }
} catch { }

# 3) Nur die Skripte entfernen, die im Paket enthalten sind
if (Test-Path $ScriptsDir) {
    Get-ChildItem -Path $ScriptsDir -Filter *.ps1 -File -ErrorAction SilentlyContinue | ForEach-Object {
        $dest = Join-Path $TargetScriptsDir $_.Name
        if (Test-Path $dest) { Remove-Item $dest -Force }
    }
}

# 4) C:\Scripts loeschen, wenn leer
if (Test-Path $TargetScriptsDir) {
    if (-not (Get-ChildItem $TargetScriptsDir -Force -ErrorAction SilentlyContinue)) {
        Remove-Item $TargetScriptsDir -Force
    }
}

exit 0
