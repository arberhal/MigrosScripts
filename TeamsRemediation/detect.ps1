$marker = "C:\ProgramData\TeamsBootstrapper\remediated.marker"
if (Test-Path $marker) { exit 0 } else { exit 1 }
