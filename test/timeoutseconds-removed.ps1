# HostValidator.ps1
# Version 1.0.1
# Purpose: Validate host availability via DNS, ping, and port checks. Logs results to central share.

param (
    [Parameter(Position = 0)]
    [string]$Target
)

$scriptVersion = "1.0.1"
$logPath = "\\SHARE\Scripts\launch_log.txt"

Clear-Host

# === INPUT HANDLING ===
if ([string]::IsNullOrWhiteSpace($Target)) {
    $Target = Read-Host "Enter hostname or IP address"
}
if ([string]::IsNullOrWhiteSpace($Target)) {
    Write-Host "`nERROR: No input provided. Exiting." -ForegroundColor Red
    exit 1
}

# === DETERMINE HOSTNAME OR IP ===
$ip = $null
$hostname = $null
$reverseName = "Unavailable"
$netbiosName = "Unavailable"

if ($Target -match '^\d{1,3}(\.\d{1,3}){3}$') {
    $ip = $Target
    $hostname = "N/A (IP provided)"
    Write-Host "`nInput is an IP address: $ip" -ForegroundColor Cyan
} else {
    $hostname = $Target.Split(".")[0]
    Write-Host "`nUsing cleaned hostname: $hostname" -ForegroundColor Cyan

    try {
        $dnsRecord = Resolve-DnsName -Name $hostname -ErrorAction Stop | Where-Object { $_.Type -eq "A" } | Select-Object -First 1
        $ip = $dnsRecord.IPAddress
        Write-Host "Resolved IP: $ip" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Unable to resolve IP for '$hostname'. Exiting." -ForegroundColor Red
        exit 1
    }
}

# === REVERSE DNS ===
try {
    $reverseRecord = Resolve-DnsName -Name $ip -Type PTR -ErrorAction Stop
    $reverseName = $reverseRecord.NameHost.TrimEnd(".")
    Write-Host "Reverse DNS: $ip -> $reverseName" -ForegroundColor Yellow

    if ($hostname -ne "N/A (IP provided)" -and $reverseName -notlike "*$hostname*") {
        Write-Host "WARNING: Reverse DNS does not match input hostname. DNS may be stale." -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "Reverse DNS lookup failed for $ip" -ForegroundColor DarkGray
}

# === PING TEST ===
Write-Host "`nRunning ping to $ip..." -ForegroundColor Cyan
$pingResult = Test-Connection -ComputerName $ip -Count 1 -Quiet -Delay 1
if ($pingResult) {
    Write-Host "Ping Result: Host responded to ICMP" -ForegroundColor Green
} else {
    Write-Host "Ping Result: No ICMP response" -ForegroundColor Yellow
}

# === TCP PORT CHECK ===
$ports = @(135, 445, 3389)
$reachable = $false
$openPort = $null

Write-Host "`nChecking TCP ports..." -ForegroundColor Cyan

foreach ($port in $ports) {
    $check = Test-NetConnection -ComputerName $ip -Port $port -WarningAction SilentlyContinue
    if ($check.TcpTestSucceeded) {
        $portName = switch ($port) { 135 { "RPC" } 445 { "SMB" } 3389 { "RDP" } default { "Unknown" } }
        Write-Host "  Port $port ($portName): OPEN" -ForegroundColor Green
        $reachable = $true
        $openPort = $port
        break
    }
}
if (-not $reachable) {
    Write-Host "  No common ports are open (135, 445, 3389)" -ForegroundColor Red
}

# === FINAL VERDICT ===
Write-Host "`n========== FINAL VERDICT ==========" -ForegroundColor Cyan
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Timestamp:      $timestamp"
Write-Host "Version:        $scriptVersion"
Write-Host "Input:          $Target"
Write-Host "Resolved IP:    $ip"
Write-Host "Reverse DNS:    $reverseName"
Write-Host "Ping:           " -NoNewline
if ($pingResult) {
    Write-Host "RESPONDED" -ForegroundColor Green
} else {
    Write-Host "NO REPLY" -ForegroundColor Yellow
}
Write-Host "Ports Checked:  $($ports -join ', ')"

if ($reachable) {
    Write-Host "RESULT: HOST IS ONLINE (port $openPort confirmed)" -ForegroundColor Green
    if ($hostname -ne "N/A (IP provided)" -and $netbiosName -ne "Unavailable" -and $hostname.ToLower() -ne $netbiosName.ToLower()) {
        Write-Host "WARNING: Hostname mismatch - DNS says '$hostname', machine says '$netbiosName'" -BackgroundColor DarkRed -ForegroundColor White
    }
} else {
    Write-Host "RESULT: HOST IS OFFLINE OR BLOCKED (no TCP connection)" -ForegroundColor Red
}
Write-Host "===================================" -ForegroundColor Cyan

# === LOGGING ===
try {
    $logEntry = "$timestamp | v$scriptVersion | Input: $Target | IP: $ip | Ping: $($pingResult) | Port: $($openPort -ne $null)"
    Add-Content -Path $logPath -Value $logEntry
} catch {
    Write-Host "Failed to write to log file at $logPath" -ForegroundColor DarkRed
}
