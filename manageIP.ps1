#Requires -RunAsAdministrator

# Variables
$adapterName = "Ethernet" # Replace with your adapter name
$ipAddress = "192.168.1.2"  # Replace with your desired IP
$subnetMask = "255.255.255.0" # Replace with your subnet mask
$gateway = "192.168.1.1"     # Replace with your gateway
$dnsServer1 = "8.8.8.8"      # Replace with your primary DNS
$dnsServer2 = "8.8.4.4"      # Replace with your secondary DNS

# Function to convert subnet mask to prefix length
function Convert-SubnetMaskToPrefixLength($subnetMask) {
    return ($subnetMask -split '\.') |
        ForEach-Object { [Convert]::ToString($_,2).PadLeft(8,'0') } |
        ForEach-Object { ($_ -split '1').Count - 1 } |
        Measure-Object -Sum |
        Select-Object -ExpandProperty Sum
}

$prefixLength = Convert-SubnetMaskToPrefixLength $subnetMask

# Get the network adapter
$adapter = Get-NetAdapter -Name $adapterName

# Disable DHCP
Set-NetIPInterface -InterfaceAlias $adapter.InterfaceAlias -Dhcp Disabled

# Remove any existing IP address
$existingIPs = Get-NetIPAddress -InterfaceAlias $adapter.InterfaceAlias -AddressFamily IPv4
foreach ($ip in $existingIPs) {
    Remove-NetIPAddress -InterfaceAlias $adapter.InterfaceAlias -IPAddress $ip.IPAddress -Confirm:$false
}

# Set the new IP address, subnet mask (as prefix length), and gateway
New-NetIPAddress -InterfaceAlias $adapter.InterfaceAlias -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $gateway

# Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses ($dnsServer1, $dnsServer2)

Write-Host "IP address changed successfully."
