$ScriptsPath = "C:\Scripts\Add-Keyboards.ps1"
$TaskName = "\IT Education Services\FremdsprachenKeyboardLayouts"

# Script vorhanden?
if (-not (Test-Path $ScriptsPath)) {
    exit 1
}

# Task vorhanden?
$null = schtasks /query /tn $TaskName 2>$null
if ($LASTEXITCODE -ne 0) {
    exit 1
}

exit 0$TaskFolder = "\IT Education Services"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

$XmlDir = Join-Path $PackageRoot "ScheduledTasks"
$ScriptsDir = Join-Path $PackageRoot "Scripts"
$TargetScriptsDir = "C:\Scripts"

# 1) XMLs muessen existieren (im Paket)
if (-not (Test-Path $XmlDir)) { exit 1 }
$xmls = Get-ChildItem -Path $XmlDir -Filter *.xml -File -ErrorAction SilentlyContinue
if (-not $xmls -or $xmls.Count -eq 0) { exit 1 }

# 2) Jeder XML-Name muss als Task im Ordner existieren
foreach ($xml in $xmls) {
    $taskName = "$TaskFolder\$($xml.BaseName)"
    schtasks /query /tn $taskName *> $null
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# 3) Optional: alle .ps1 aus Paket muessen nach C:\Scripts kopiert sein
if (-not (Test-Path $ScriptsDir)) { exit 1 }
$pkgScripts = Get-ChildItem -Path $ScriptsDir -Filter *.ps1 -File -ErrorAction SilentlyContinue
if (-not $pkgScripts -or $pkgScripts.Count -eq 0) { exit 1 }

if (-not (Test-Path $TargetScriptsDir)) { exit 1 }

foreach ($s in $pkgScripts) {
    $dest = Join-Path $TargetScriptsDir $s.Name
    if (-not (Test-Path $dest)) { exit 1 }
}

exit 0

