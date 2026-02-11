# =========================
# Install.ps1 (SYSTEM)
# - Copies package Scripts -> C:\Scripts
# - Copies package XML/PS1 -> C:\ProgramData\IT-Education-Services\{ScheduledTasks,Scripts}
# - Writes manifest.json for reliable detection
# - Ensures Task Scheduler folder exists and imports all XMLs into it
# =========================

$ErrorActionPreference = "Stop"

$CompanyRoot      = "C:\ProgramData\IT-Education-Services"
$CompanyXmlCache  = Join-Path $CompanyRoot "ScheduledTasks"
$CompanyPsCache   = Join-Path $CompanyRoot "Scripts"
$TargetScriptsDir = "C:\Scripts"
$TaskFolderName   = "IT Education Services"
$TaskFolderPath   = "\$TaskFolderName"
$ManifestPath     = Join-Path $CompanyRoot "manifest.json"

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PackageXmlDir = Join-Path $PackageRoot "ScheduledTasks"
$PackagePsDir  = Join-Path $PackageRoot "Scripts"

# 0) Ensure required package folders exist
if (-not (Test-Path $PackageXmlDir)) { throw "Missing package folder: $PackageXmlDir" }
if (-not (Test-Path $PackagePsDir))  { throw "Missing package folder: $PackagePsDir" }

$xmls = Get-ChildItem -Path $PackageXmlDir -Filter *.xml -File
if ($xmls.Count -lt 1) { throw "No XML files found in $PackageXmlDir" }

$ps1s = Get-ChildItem -Path $PackagePsDir -Filter *.ps1 -File
if ($ps1s.Count -lt 1) { throw "No PS1 files found in $PackagePsDir" }

# 1) Ensure local directories exist
$dirsToCreate = @(
  $CompanyRoot, $CompanyXmlCache, $CompanyPsCache,
  $TargetScriptsDir
)
foreach ($d in $dirsToCreate) {
  if (-not (Test-Path $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null }
}

# 2) Copy scripts to runtime location
Copy-Item -Path (Join-Path $PackagePsDir "*") -Destination $TargetScriptsDir -Recurse -Force

# 3) Cache package content for reliable detection
Copy-Item -Path (Join-Path $PackageXmlDir "*") -Destination $CompanyXmlCache -Recurse -Force
Copy-Item -Path (Join-Path $PackagePsDir  "*") -Destination $CompanyPsCache  -Recurse -Force

# 4) Create manifest.json (dynamic, no hardcoding)
$manifest = [ordered]@{
  packageVersion = "1.0.0"  # optional: update manually if you want explicit versioning
  createdUtc     = (Get-Date).ToUniversalTime().ToString("o")
  taskFolder     = $TaskFolderPath
  tasks          = @()
  scripts        = @()
}

foreach ($x in $xmls) {
  $manifest.tasks += [ordered]@{
    xmlFile   = $x.Name
    taskName  = $x.BaseName
    taskPath  = "$TaskFolderPath\$($x.BaseName)"
  }
}

foreach ($s in $ps1s) {
  $manifest.scripts += [ordered]@{
    fileName     = $s.Name
    runtimePath  = (Join-Path $TargetScriptsDir $s.Name)
    cachePath    = (Join-Path $CompanyPsCache $s.Name)
  }
}

($manifest | ConvertTo-Json -Depth 6) | Set-Content -Path $ManifestPath -Encoding UTF8

# 5) Ensure Task Scheduler folder exists
$service = New-Object -ComObject "Schedule.Service"
$service.Connect()
$rootFolder = $service.GetFolder("\")
try { $rootFolder.GetFolder($TaskFolderPath) | Out-Null }
catch { $rootFolder.CreateFolder($TaskFolderPath) | Out-Null }

# 6) Import all tasks from XML (overwrite)
foreach ($x in $xmls) {
  $tn = "$TaskFolderPath\$($x.BaseName)"
  schtasks /create /tn $tn /xml $x.FullName /f | Out-Null
}

exit 0
