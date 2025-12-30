# Simple Windows watcher that checks public IP and runs DNS up/down scripts.
# Requires: run as Administrator. Best run as a Scheduled Task at logon.
param(
    [string]$InterfaceAlias = 'Ethernet',
    [string]$VpnServerIp = '',
    [int]$IntervalSeconds = 5
)

function Get-PublicIp {
    # Try multiple services
    $services = @('https://ifconfig.me','https://ipinfo.io/ip','https://icanhazip.com')
    foreach ($s in $services) {
        try {
            $ip = (Invoke-WebRequest -Uri $s -UseBasicParsing -TimeoutSec 3).Content.Trim()
            if ($ip -match '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') { return $ip }
        } catch { }
    }
    return $null
}

$lastState = 'unknown'
while ($true) {
    $currentIp = Get-PublicIp
    if ($VpnServerIp -and $currentIp -and $currentIp -eq $VpnServerIp) {
        if ($lastState -ne 'up') {
            Write-Output "[windows-wg-watcher] VPN detected UP -> set DNS"
            & pwsh -Command "& './scripts/windows-dns-up.ps1' -InterfaceAlias '$InterfaceAlias' -Dns @('1.1.1.1','8.8.8.8')" 2>$null
            $lastState = 'up'
        }
    } else {
        if ($lastState -ne 'down') {
            Write-Output "[windows-wg-watcher] VPN detected DOWN -> restore DNS"
            & pwsh -Command "& './scripts/windows-dns-down.ps1' -InterfaceAlias '$InterfaceAlias' -Mode 'fallback' -Fallback @('192.168.1.1','223.5.5.5')" 2>$null
            $lastState = 'down'
        }
    }
    Start-Sleep -Seconds $IntervalSeconds
}
