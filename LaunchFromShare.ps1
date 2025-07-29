# LaunchFromShare.ps1
# Version: 1.0.0

$ScriptRoot = "\\SHARE\Scripts"
$LogFile = Join-Path $ScriptRoot "launch_log.txt"

Clear-Host
Write-Host "=== SOC Tool Launcher ===" -ForegroundColor Cyan

# --- Validate script folder
if (-not (Test-Path $ScriptRoot)) {
    Write-Host "ERROR: Network share path not accessible: $ScriptRoot" -ForegroundColor Red
    exit 1
}

# --- Get all *.ps1 scripts excluding this launcher
$availableScripts = Get-ChildItem -Path $ScriptRoot -Filter *.ps1 | Where-Object { $_.Name -ne "LaunchFromShare.ps1" }

if (-not $availableScripts) {
    Write-Host "No scripts found in $ScriptRoot." -ForegroundColor Yellow
    exit 0
}

# --- Prompt user to pick a script
$scriptNames = $availableScripts.Name
$choice = $scriptNames | Out-GridView -Title "Select a SOC Tool to Run" -OutputMode Single

if (-not $choice) {
    Write-Host "No script selected. Exiting." -ForegroundColor DarkGray
    exit 0
}

$selectedScriptPath = Join-Path $ScriptRoot $choice
Write-Host "`nLaunching: $choice" -ForegroundColor Green

# --- Log execution
try {
    $username = $env:USERNAME
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp | $username ran $choice from launcher"
    Add-Content -Path $LogFile -Value $logLine
} catch {
    Write-Host "Warning: Failed to write to log file: $LogFile" -ForegroundColor Yellow
}

# --- Run the script in a new window
Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$selectedScriptPath`""
