# =========================
# Detection.ps1 (Intune Win32 custom detection)
# - Reads C:\ProgramData\IT-Education-Services\manifest.json
# - Verifies:
#   * All listed tasks exist
#   * All listed runtime scripts exist
# - Returns:
#   exit 0 = installed
#   exit 1 = not installed
# =========================

$ErrorActionPreference = "SilentlyContinue"

$CompanyRoot  = "C:\ProgramData\IT-Education-Services"
$ManifestPath = Join-Path $CompanyRoot "manifest.json"

if (-not (Test-Path $ManifestPath)) { exit 1 }

$manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
if (-not $manifest) { exit 1 }

# Check scripts exist
foreach ($s in $manifest.scripts) {
  if (-not (Test-Path $s.runtimePath)) { exit 1 }
}

# Check tasks exist
foreach ($t in $manifest.tasks) {
  schtasks /query /tn $t.taskPath *> $null
  if ($LASTEXITCODE -ne 0) { exit 1 }
}

exit 0
