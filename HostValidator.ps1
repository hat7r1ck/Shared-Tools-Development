param (
    [Parameter(Position = 0)]
    [string]$Target
)

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
$pingResult = Test-Connection -ComputerName $ip -Count 2 -Quiet -TimeoutSeconds 1
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

# === NETBIOS NAME CHECK (if reachable) ===
if ($reachable) {
    Write-Host "`nQuerying NetBIOS name using nbtstat..." -ForegroundColor Cyan
    try {
        $nbtstatOutput = nbtstat -A $ip
        $match = $nbtstatOutput | Select-String -Pattern '^\s*([^\s]+)\s+<00>\s+UNIQUE'
        if ($match) {
            $netbiosName = $match.Matches[0].Groups[1].Value.Trim()
            Write-Host "NetBIOS Name: $netbiosName" -ForegroundColor Green
        } else {
            Write-Host "Could not extract NetBIOS name." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "nbtstat command failed." -ForegroundColor Red
    }
}

# === FINAL VERDICT ===
Write-Host "`n========== FINAL VERDICT ==========" -ForegroundColor Cyan
Write-Host "Timestamp:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Input:          $Target"
Write-Host "Resolved IP:    $ip"
Write-Host "Reverse DNS:    $reverseName"
Write-Host "NetBIOS Name:   $netbiosName"
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
        Write-Host "WARNING: Hostname mismatch — DNS says '$hostname', machine says '$netbiosName'" -BackgroundColor DarkRed -ForegroundColor White
    }
} else {
    Write-Host "RESULT: HOST IS OFFLINE OR BLOCKED (no TCP connection)" -ForegroundColor Red
}
Write-Host "===================================" -ForegroundColor Cyan
