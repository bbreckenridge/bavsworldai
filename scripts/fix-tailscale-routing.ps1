Write-Host 'Checking for Tailscale route collisions on the K3s subnet...'
$ifIndex = (Get-NetAdapter | Where-Object Name -match 'K3sNatSwitch' -ErrorAction SilentlyContinue).ifIndex
if ($ifIndex) {
    Set-NetRoute -InterfaceIndex $ifIndex -DestinationPrefix '<LAN-SUBNET>' -RouteMetric 1 -Confirm:$false -ErrorAction SilentlyContinue
    Set-NetIPInterface -InterfaceIndex $ifIndex -InterfaceMetric 1 -PassThru | Out-Null
    Write-Host 'Success: Routing priority restored for K3s Virtual Switch (192.168.100.x).'
} else {
    Write-Host 'K3sNatSwitch adapter not found. No action taken.'
}
