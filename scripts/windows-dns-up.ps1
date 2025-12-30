# Requires: run as Administrator
param(
    [string]$InterfaceAlias = 'Ethernet',
    [string[]]$Dns = @('1.1.1.1','8.8.8.8')
)
Write-Output "[windows-dns-up] Setting DNS for $InterfaceAlias -> $($Dns -join ',')"
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $Dns
Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias | Format-List
