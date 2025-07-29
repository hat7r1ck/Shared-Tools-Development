param (
    [Parameter(Position = 0)]
    [string]$Target
)

# === VERSION TAG ===
$ScriptVersion = "v1.3.0"
$LogPath = "\\SHARE\Scripts\launch_log.txt"  # <-- Update as needed

Clear-Host
Write-Host "SOC Host Validator - $ScriptVersion`n" -ForegroundColor Cyan

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
$pingResult = Test-Connection -ComputerName $ip -Count 2 -Quiet
if ($pingResult) {
    Write-Host "Ping Result: Host responded to ICMP" -ForegroundColor Green
} else {
    Write-Host "Ping Result: No ICMP response" -ForegroundColor Yellow
}

# === TCP PORT CHECK WITH TIMEOUT WORKAROUND ===
$ports = @(135, 445, 3389)
$reachable = $false
$openPort = $null

Write-Host "`nChecking TCP ports..." -ForegroundColor Cyan
foreach ($port in $ports) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($ip, $port, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne(1500, $false)
        if ($success -and $tcp.Connected) {
            $tcp.EndConnect($iar)
            $tcp.Close()
            $reachable = $true
            $openPort = $port
            Write-Host "  Port $port: OPEN" -ForegroundColor Green
            break
        } else {
            $tcp.Close()
            Write-Host "  Port $port: CLOSED or BLOCKED" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Port $port: ERROR during check" -ForegroundColor DarkGray
    }
}

# === FINAL VERDICT ===
Write-Host "`n========== FINAL VERDICT ==========" -ForegroundColor Cyan
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Timestamp:      $timestamp"
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
} else {
    Write-Host "RESULT: HOST IS OFFLINE OR BLOCKED (no TCP connection)" -ForegroundColor Red
}
Write-Host "===================================" -ForegroundColor Cyan

# === LOGGING ===
try {
    $user = $env:USERNAME
    $logLine = "$timestamp`t$user`t$Target`t$ip`t$reverseName`tPing: $pingResult`tTCP: $reachable (Port $openPort)"
    Add-Content -Path $LogPath -Value $logLine
} catch {
    Write-Host "`nWARNING: Could not write to log at $LogPath" -ForegroundColor DarkYellow
}
