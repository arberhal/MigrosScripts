$ScriptsPath = "C:\Scripts"
$TaskFolder = "\IT Education Services"
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 1. C:\Scripts sicherstellen
if (-not (Test-Path $ScriptsPath)) {
    New-Item -Path $ScriptsPath -ItemType Directory -Force
}

# 2. Skripte kopieren
Copy-Item -Path "$PackageRoot\Scripts\*" -Destination $ScriptsPath -Recurse -Force

# 3. Task-Ordner erstellen (falls nicht vorhanden)
$service = New-Object -ComObject "Schedule.Service"
$service.Connect()
$rootFolder = $service.GetFolder("\")
try {
    $rootFolder.GetFolder($TaskFolder) | Out-Null
} catch {
    $rootFolder.CreateFolder($TaskFolder) | Out-Null
}

# 4. Scheduled Tasks importieren
Get-ChildItem "$PackageRoot\ScheduledTasks\*.xml" | ForEach-Object {
    schtasks /create `
        /tn "$TaskFolder\$($_.BaseName)" `
        /xml "$($_.FullName)" `
        /f
}
