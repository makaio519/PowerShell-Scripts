# PowerShell Script to Set Ethernet Adapter to Obtain IP and DNS Automatically

# Get the name of the Ethernet adapter (modify if needed)
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq 'Up' -and $_.Name -like '*Ethernet*'} | Select-Object -First 1

if ($adapter -eq $null) {
    Write-Host "No active Ethernet adapter found." -ForegroundColor Red
    exit 1
}

$adapterName = $adapter.Name
Write-Host "Configuring adapter: $adapterName"

# Set IP to be obtained automatically (DHCP)
Try {
    Write-Host "Setting IP address to DHCP..."
    Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled -ErrorAction Stop

    # Remove all static IP addresses (if any)
    $ipAddresses = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
    foreach ($ip in $ipAddresses) {
        if ($ip.PrefixOrigin -ne 'Dhcp') {
            Remove-NetIPAddress -InterfaceAlias $adapterName -IPAddress $ip.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    # Remove static gateways (if any)
    Write-Host "Removing any static gateways..."
    $gateways = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
    foreach ($gw in $gateways) {
        Remove-NetRoute -InterfaceAlias $adapterName -DestinationPrefix $gw.DestinationPrefix -NextHop $gw.NextHop -Confirm:$false -ErrorAction SilentlyContinue
    }

    # Set DNS to automatic
    Write-Host "Setting DNS servers to be obtained automatically..."
    Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses -ErrorAction Stop

    # Refresh IP and DNS settings
    Write-Host "Releasing and renewing IP address..."
    ipconfig /release
    ipconfig /renew

    Write-Host "Flushing DNS resolver cache..."
    ipconfig /flushdns

    Write-Host "Configuration completed successfully." -ForegroundColor Green
}
Catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
