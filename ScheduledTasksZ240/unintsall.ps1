# =========================
# Uninstall.ps1 (SYSTEM)
# - Uses manifest.json if present
# - Removes:
#   * Tasks listed in manifest
#   * Runtime scripts listed in manifest
#   * IT Education Services folder if empty
#   * Cached content + manifest
#   * C:\Scripts if empty (optional)
# =========================

$ErrorActionPreference = "SilentlyContinue"

$CompanyRoot      = "C:\ProgramData\IT-Education-Services"
$CompanyXmlCache  = Join-Path $CompanyRoot "ScheduledTasks"
$CompanyPsCache   = Join-Path $CompanyRoot "Scripts"
$ManifestPath     = Join-Path $CompanyRoot "manifest.json"
$TargetScriptsDir = "C:\Scripts"

$TaskFolderName = "IT Education Services"
$TaskFolderPath = "\$TaskFolderName"

$manifest = $null
if (Test-Path $ManifestPath) {
  $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
}

# 1) Remove tasks (prefer manifest)
if ($manifest -and $manifest.tasks) {
  foreach ($t in $manifest.tasks) {
    schtasks /delete /tn $t.taskPath /f *> $null
  }
} else {
  # Fallback: remove all tasks in folder
  try {
    $svc = New-Object -ComObject "Schedule.Service"
    $svc.Connect()
    $folder = $svc.GetFolder($TaskFolderPath)
    foreach ($task in @($folder.GetTasks(0))) {
      $folder.DeleteTask($task.Name, 0)
    }
  } catch {}
}

# 2) Delete task folder if empty
try {
  $svc = New-Object -ComObject "Schedule.Service"
  $svc.Connect()
  $root = $svc.GetFolder("\")
  $folder = $svc.GetFolder($TaskFolderPath)
  if ($folder.GetTasks(0).Count -eq 0) {
    $root.DeleteFolder($TaskFolderPath, 0)
  }
} catch {}

# 3) Remove scripts (prefer manifest)
if ($manifest -and $manifest.scripts) {
  foreach ($s in $manifest.scripts) {
    if ($s.runtimePath -and (Test-Path $s.runtimePath)) {
      Remove-Item $s.runtimePath -Force
    }
  }
} else {
  # Fallback: do nothing (safer than deleting arbitrary scripts)
}

# 4) Optional: remove C:\Scripts if empty
if (Test-Path $TargetScriptsDir) {
  if (-not (Get-ChildItem $TargetScriptsDir -Force | Select-Object -First 1)) {
    Remove-Item $TargetScriptsDir -Force
  }
}

# 5) Remove cached content + manifest
if (Test-Path $CompanyXmlCache) { Remove-Item $CompanyXmlCache -Recurse -Force }
if (Test-Path $CompanyPsCache)  { Remove-Item $CompanyPsCache  -Recurse -Force }
if (Test-Path $ManifestPath)    { Remove-Item $ManifestPath -Force }

# Remove root folder if empty
if (Test-Path $CompanyRoot) {
  if (-not (Get-ChildItem $CompanyRoot -Force | Select-Object -First 1)) {
    Remove-Item $CompanyRoot -Force
  }
}

exit 0
