# Force 64-bit PowerShell if Intune runs 32-bit
if ($env:PROCESSOR_ARCHITEW6432 -and $PSHOME -like "*SysWOW64*") {
  & "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
  exit $LASTEXITCODE
}

$targetNames = @(
  "RICOH PCL6 UniversalDriver V4.42",
  "PCL6 Driver for Universal Print"
)

try {
  $drivers = Get-PrinterDriver -ErrorAction Stop
  foreach ($t in $targetNames) {
    if ($drivers.Name -contains $t) { exit 0 }
  }
} catch {}

exit 1
