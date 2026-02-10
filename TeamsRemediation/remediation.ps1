$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$bootstrapperUrl  = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"
$workDir          = "C:\ProgramData\TeamsBootstrapper"
$bootstrapperPath = Join-Path $workDir "teamsbootstrapper.exe"
$logPath          = Join-Path $workDir "teamsbootstrapper-remediation.log"
$marker           = Join-Path $workDir "remediated.marker"

function Log($msg) {
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    try { Add-Content -Path $logPath -Value $line -Encoding UTF8 } catch {}
}

try {
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    Log "=== Start Teams bootstrapper run ==="

    try {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    } catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Log "Downloading teamsbootstrapper..."
    Invoke-WebRequest -Uri $bootstrapperUrl -OutFile $bootstrapperPath -UseBasicParsing -TimeoutSec 120

    Log "Running teamsbootstrapper -p..."
    $proc = Start-Process -FilePath $bootstrapperPath -ArgumentList "-p" -PassThru -NoNewWindow
    if (-not ($proc | Wait-Process -Timeout 600)) {
        try { $proc | Stop-Process -Force } catch {}
        throw "teamsbootstrapper timed out after 600 seconds."
    }
    if ($proc.ExitCode -ne 0) {
        throw "teamsbootstrapper returned exit code $($proc.ExitCode)"
    }

    New-Item -ItemType File -Path $marker -Force | Out-Null
    Log "Marker created: $marker"
    Log "=== SUCCESS ==="
    exit 0
}
catch {
    Log "=== FAILED ==="
    Log "Error: $($_.Exception.Message)"
    exit 1
}
