## 
##    Postinstall network configuration script
##
##   All rights reserved https://github.com/itpalefox
param([switch]$task)
if ($task) {
	schtasks /create /tn "ifcfg" /sc onstart /delay 0000:30 /rl highest /ru system /tr "powershell.exe -file C:\ifcfg.ps1" /f
	Write-Host "You need to reboot your server!"
} else {
	
$IP = "192.168.55.22"
$MaskBits = 24 # This means subnet mask = 255.255.255.0
$Gateway = "192.168.55.1"
$Dns = "8.8.8.8,1.1.1.1"
$IPType = "IPv4"
$MacTg = "0A-00-27-00-00-11" # Format like 0A-00-27-00-00-11

function WriteLog
{
    Param ([string]$LogString)
    $LogFile = "C:\ifcfg_" + (Get-Date).tostring("yyyyMMdd") + ".log"
    $DateTime = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    $LogMessage = "$Datetime $LogString"
    Add-content $LogFile -value $LogMessage
}
# Try to ping world
if (Test-Connection -ComputerName 8.8.8.8 -Count 3 -Delay 2 -Quiet) {
	WriteLog "Ping to GW and DNS is OK!"
	if(schtasks /Query /TN "ifcfg" /V /FO List) {
		WriteLog "Found task, but ping is OK! Delete task"
		schtasks /Delete /TN "ifcfg" /f
	}
} else {
	WriteLog "Ping to GW and DNS is failed :("
	if ((Get-NetAdapter | ? {$_.Status -eq "Not Present"}).MacAddress -eq "") {
		WriteLog "Found broken driver!!! Trying to fix driver"
        $neterror= ((((Get-NetAdapter).InterfaceDescription) -split "\s")[0,1,2,3]) -Join ' '
        $driver=(Get-WmiObject Win32_PnpSignedDriver | select DeviceName,InfName |where {$_.devicename -like ((echo "*" $neterror "*") -join '') }).InfName[0]
        pnputil.exe /delete-driver $driver /uninstall
		WriteLog "Broken driver deleted! Wait new driver apply"
		Start-Sleep -s 10
	}
# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"} | ? {$_.MacAddress -eq $MacTg}
if ($adapter) {
WriteLog "Clear network adapter configuration"
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
WriteLog "Configure network adapter"
 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
 -AddressFamily $IPType `
 -IPAddress $IP `
 -PrefixLength $MaskBits `
 -DefaultGateway $Gateway
# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
WriteLog "Reload network adapter"
Disable-NetAdapter -Name ($adapter).Name -Confirm:$false
Enable-NetAdapter -Name ($adapter).Name
} else {
	WriteLog "Adapter not found!!! Check if MAC is correct"
	break
}
}
}