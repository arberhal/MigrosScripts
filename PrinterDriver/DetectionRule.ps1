$targets = @(
  "RICOH PCL6 UniversalDriver V4.42",
  "PCL6 Driver for Universal Print"
)

# 1) CIM/WMI (Win32_PrinterDriver) - Name includes ",<ver>,Windows x64"
try {
  $wmi = Get-CimInstance -ClassName Win32_PrinterDriver -ErrorAction Stop

  foreach ($t in $targets) {
    if ($wmi | Where-Object { $_.Name -like "$t,*" }) { exit 0 }
  }
} catch {
  # continue
}

# 2) Fallback: Get-PrinterDriver exact name
try {
  $drivers = Get-PrinterDriver -ErrorAction Stop
  foreach ($t in $targets) {
    if ($drivers.Name -contains $t) { exit 0 }
  }
} catch {}

exit 1
