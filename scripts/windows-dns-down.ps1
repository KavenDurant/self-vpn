# Requires: run as Administrator
param(
    [string]$InterfaceAlias = 'Ethernet',
    [string]$Mode = 'dhcp', # dhcp | fallback
    [string[]]$Fallback = @('192.168.1.1','223.5.5.5')
)
if ($Mode -eq 'dhcp') {
    Write-Output "[windows-dns-down] Switching $InterfaceAlias to DHCP for DNS"
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses
} else {
    Write-Output "[windows-dns-down] Restoring fallback DNS: $($Fallback -join ',')"
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $Fallback
}
Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias | Format-List
