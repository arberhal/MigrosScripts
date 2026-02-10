$roots = @(
  "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3",
  "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-4"
)

$found = $false

foreach ($root in $roots) {
  if (Test-Path $root) {
    foreach ($k in Get-ChildItem $root -ErrorAction SilentlyContinue) {
      $n = $k.PSChildName
      if ($n -like "*Ricoh*" -or $n -like "*PCL6*") { $found = $true; break }
    }
  }
  if ($found) { break }
}

if ($found) { exit 0 } else { exit 1 }
