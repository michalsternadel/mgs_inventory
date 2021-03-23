@ECHO OFF
REM MgS Inventory script for Windows

REM Licence: GPLv2

REM  mgs_inventory - script to collect system info to your zabbix.
REM  Copyright (C) 2016-2021 Michal Sternadel <michal@sternadel.pl>
REM 
REM  mgs_inventory is free software: you can redistribute it and/or modify
REM  it under the terms of the GNU General Public License as published by
REM  the Free Software Foundation, either version 2 of the License, or
REM  later version.
REM 
REM  mgs_inventory is distributed in the hope that it will be useful,
REM  but WITHOUT ANY WARRANTY; without even the implied warranty of
REM  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM  GNU General Public License for more details.
REM 
REM  You should have received a copy of the GNU General Public License
REM  along with mgs_inventory.  If not, see <http://www.gnu.org/licenses/>.

SET VERSION=0.0.16
@setlocal enableextensions enabledelayedexpansion
SET ZBXPATH=C:\Zabbix\
SET -module=
SET -item=
SET -param=
FOR %%A IN (%*) DO (
   FOR /f "tokens=1,2 delims=:" %%G IN ("%%A") DO SET %%G=%%~H
)
SET module=%-module%
SET item=%-item%
SET param=%-param%
IF "%module%"=="uptime" ( SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$o=Get-WmiObject win32_operatingsystem; (((Get-Date) - ($o.ConvertToDateTime($o.lastbootuptime))).TotalSeconds.ToString() -Split ',')[0]" )
IF "%module%"=="self" ( 
    IF "%item%"=="availability" SET command=echo "1"
    IF "%item%"=="version" SET command=echo "%VERSION%"
)
IF "%module%"=="cpu" (
    IF "%item%"=="model" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_Processor).Name|Select-Object -First 1"
    IF "%item%"=="freq" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_Processor).MaxClockSpeed|Select-Object -First 1"
    IF "%item%"=="curfreq" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_Processor).CurrentClockSpeed|Select-Object -First 1"
    IF "%item%"=="cores" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors"
    IF "%item%"=="cpus" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_ComputerSystem).NumberOfProcessors"
    IF "%item%"=="count" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors"
    IF "%item%"=="arch" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$env:processor_architecture"
)
IF "%module%"=="memory" (    
    IF "%item%"=="total" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_PhysicalMemory|Measure-Object -Property Capacity -Sum).Sum"
    IF "%item%"=="freq" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_Processor).MaxClockSpeed"
    IF "%item%"=="partnumber" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_PhysicalMemory).PartNumber"
    IF "%item%"=="manufacturer" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_PhysicalMemory).Manufacturer"
    IF "%item%"=="capacity" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_PhysicalMemory).Capacity"
)
IF "%module%"=="storage" ( 
    IF "%item%" == "partitions" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WMIObject -Class Win32_LogicalDisk  -Filter {MediaType='12'} | Select-Object -Property DeviceId, @{n='Size';e={[math]::Round($_.Size/1GB,2)}} | ft -hidetableheaders" 
    IF "%item%" == "disks" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WMIObject -Class Win32_DiskDrive -Filter {MediaType='Fixed hard disk media'} | Select-Object -Property DeviceId, @{n='Size';e={[math]::Round($_.Size/1GB,2)}} | ft -hidetableheaders" 
    IF "%item%" == "model" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WMIObject -Class Win32_DiskDrive -Filter {MediaType='Fixed hard disk media'} | Select-Object -Property DeviceId, Model | ft -hidetableheaders" 
    )
IF "%module%"=="network" ( 
    IF "%item%"=="nic" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_NetworkAdapter -ComputerName . -Filter 'physicaladapter=true' | select -expand name)|Sort-Object"
    IF "%item%"=="ipv4" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -class Win32_NetworkAdapterConfiguration -ComputerName . -filter 'IPEnabled=true' | select -expand IpAddress | Where-Object { ([Net.IPAddress]$_).AddressFamily -eq 'InterNetwork' }|Sort-Object"
    IF "%item%"=="ipv6" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -class Win32_NetworkAdapterConfiguration -ComputerName . -filter 'IPEnabled=true' | select -expand IpAddress | Where-Object { ([Net.IPAddress]$_).AddressFamily -ne 'InterNetwork' }|Sort-Object"
    IF "%item%"=="ipv4gateway" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -class Win32_NetworkAdapterConfiguration -ComputerName . -filter 'IPEnabled=true' | select -expand DefaultIpGateway | Where-Object { ([Net.IPAddress]$_).AddressFamily -eq 'InterNetwork' } "
    IF "%item%"=="ipv6gateway" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -class Win32_NetworkAdapterConfiguration -ComputerName . -filter 'IPEnabled=true' | select -expand DefaultIpGateway | Where-Object { ([Net.IPAddress]$_).AddressFamily -ne 'InterNetwork' } "
    IF "%item%"=="extipv4" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ip=Invoke-RestMethod -Uri 'https://api.ipify.org?format=json';$($ip.ip)"
    IF "%item%"=="extipv6" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ip=Invoke-RestMethod -Uri 'https://api6.ipify.org?format=json';$($ip.ip)"
)
IF "%module%"=="os" ( 
    IF "%item%"=="desc" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject -class Win32_OperatingSystem -ComputerName .).Caption"
    IF "%item%"=="fulldesc" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject -class Win32_OperatingSystem -ComputerName .).Caption + ', SP' + (Get-WmiObject -class Win32_OperatingSystem -ComputerName .).ServicePackMajorVersion + ', ' + (Get-WmiObject -class Win32_OperatingSystem -ComputerName .).OSArchitecture + ', ' + (Get-WmiObject -class Win32_OperatingSystem -ComputerName .).Version"
    IF "%item%"=="serial" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -class Win32_OperatingSystem -ComputerName . | Select-Object -Property SerialNumber | ft -hidetableheaders"
    IF "%item%"=="productkey" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Commend "$k=$null; $wmi=[WMIClass]'\\.\root\default:stdRegProv'; $v=($wmi.GetBinaryValue(2147483650,'Software\Microsoft\Windows NT\CurrentVersion','DigitalProductId4').uValue)[52..66]; $c='B','C','D','E','F','G','H','J','K','M','P','Q','R','T','V','W','X','Y','2','3','4','5','6','7','8','9'; For ($i=24; $i -ge 0; $i--) { $k=0; For ($j=14; $j -ge 0; $j--) { $k=$k * 256 -bxor $v[$j]; $v[$j]=[math]::truncate($k / 24); $k=$k % 24; }; $k=$c[$k]+$k; If (($i % 5 -eq 0) -and ($i -ne 0)) { $k='-'+$k; }; }; $o=New-Object Object; $o | Add-Member Noteproperty ProductKey -value $k; $o | Select-Object -Property ProductKey -First 1 | ft -hidetableheaders;"
    IF "%item%"=="version" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject -class Win32_OperatingSystem -ComputerName . | Select-Object -Property Version | ft -hidetableheaders"
    IF "%item%"=="guid" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "get-wmiobject Win32_ComputerSystemProduct  | Select-Object -ExpandProperty UUID"
    IF "%item%"=="installdate" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate)"
    IF "%item%"=="machineguid" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Cryptography).MachineGuid"
)
IF "%module%"=="var" ( 
    IF "%item%"=="hostname" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_ComputerSystem -ComputerName . | select -expand DNSHostName"
    IF "%item%"=="fqdn" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_ComputerSystem -ComputerName .).DNSHostName+'.'+(Get-WmiObject Win32_ComputerSystem -ComputerName .).Domain"
    IF "%item%"=="domain" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_ComputerSystem -ComputerName .).Domain"
    IF "%item%"=="vendor" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty Manufacturer"
    IF "%item%"=="bios" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-WmiObject Win32_BIOS | Select-Object Name, Version | Format-List"
    IF "%item%"=="bitlocker" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-BitlockerVolume"
    IF "%item%"=="gfx" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_VideoController).caption|Sort-Object"
    IF "%item%"=="display" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$(foreach($b in $(Get-WMIObject WmiMonitorID -Namespace root\wmi)) { [System.Text.Encoding]::ASCII.GetString($b.UserFriendlyName)})|Sort-Object"
)
IF "%module%"=="serial" ( 
    IF "%item%"=="display" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$(foreach($b in $(Get-WMIObject WmiMonitorID -Namespace root\wmi)) { [System.Text.Encoding]::ASCII.GetString($b.SerialNumberId)})|Sort-Object"
    IF "%item%"=="bios" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_Bios).SerialNumber|Sort-Object"
    IF "%item%"=="cpu" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_Processor).ProcessorId|Sort-Object"
    IF "%item%"=="storage" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_PhysicalMedia).SerialNumber|Sort-Object"
    IF "%item%"=="chassis" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_SystemEnclosure).SerialNumber|Sort-Object"
    IF "%item%"=="nic" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_NetworkAdapter -ComputerName . -Filter 'physicaladapter=true').MACAddress|Sort-Object"
    IF "%item%"=="memory" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-WmiObject Win32_PhysicalMemory).SerialNumber|Sort-Object"
    
)
IF "%module%"=="software" ( 
    IF "%item%"=="installed" (
        SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | where{$_ -ne ""} | Sort-Object -Property InstallDate,DisplayName |ft -AutoSize -hidetableheaders"
        IF "%param%"=="count" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).Count"
        IF "%param%"=="extra" SET command=PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.Publisher -notlike 'Microsoft*' } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | where{$_ -ne ''} | Sort-Object -Property InstallDate |ft -AutoSize -hidetableheaders |Out-String).Trim()"        
    )        
)
IF "%module%"=="" ( SET command=echo ZBX_NOTSUPPORTED ) & GOTO strip

:strip
    FOR /F "tokens=* USEBACKQ" %%F IN (`%command%`) DO (
	SET out=%%~F
	REM echo.|set /p="!out!"
	echo.!out!
    )
GOTO end

:end
exit /b
