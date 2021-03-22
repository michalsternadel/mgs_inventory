#!/bin/bash
# MgS Inventory script for Linux

# Licence: GPLv2

#  mgs_inventory - script to collect system info to your zabbix.
#  Copyright (C) 2016-2021 Michal Sternadel <michal@sternadel.pl>
# 
#  mgs_inventory is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  later version.
# 
#  mgs_inventory is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with mgs_inventory.  If not, see <http://www.gnu.org/licenses/>.

VERSION=0.0.16
ZABBIXPATH="/etc/zabbix/"

while getopts "m:i:p:a:" OPTION
do
    case $OPTION in
	m) 
	    module=${OPTARG}
	;;
	i)
	    item=${OPTARG}
	;;
	p)
	    param=${OPTARG}
	;;
	a)
	    additionalparams=${OPTARG}
	;;
    esac
done

case ${module} in
	"uptime")
		cat /proc/uptime | awk -F. {'print $1'}
	;;
    "self")
	case ${item} in
	    "availability")
		echo "1"
	    ;;
	    "version")
			echo $VERSION
	    ;;
	    *)
		echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
    ;;
    "cpu")
	case ${item} in
	    "model")
		cat /proc/cpuinfo | grep "model name" |awk -F": " {'print $2'} | head -n1
	    ;;
	    "freq")
		for freq in `cat /proc/cpuinfo | grep "model name" |awk -F"@ " {'print $2'} | sed -e 's/[A-Z]//gi' -e 's/\.//g' | head -n1` ; do
		    echo $(($freq * 10))
		done
	    ;;
	    "curfreq")
			cat /proc/cpuinfo | grep "cpu MHz" |awk -F": " {'print $2'} | sed 's/[A-Z]//gi' | head -n1
	    ;;
	    "cpus")
			LC_ALL=en_US lscpu | grep "Socket(s):" | awk {'print $2'}
	    ;;
	    "cores")
			corespersocket=`LC_ALL=en_US lscpu | grep "Core(s)" | awk -F":" {'print $2'}`
			sockets=`LC_ALL=en_US lscpu | grep "Socket(s):" | awk {'print $2'}`
			echo $(($corespersocket * $sockets))
	    ;;
	    "count")
			corespersocket=`LC_ALL=en_US lscpu | grep "Core(s)" | awk -F":" {'print $2'}`
			sockets=`LC_ALL=en_US lscpu | grep "Socket(s):" | awk {'print $2'}`
			echo $(($corespersocket * $sockets))
	    ;;
	    "threads")
			threadspercore=`LC_ALL=en_US lscpu | grep "Thread(s)" | awk -F":" {'print $2'}`
			corespersocket=`LC_ALL=en_US lscpu | grep "Core(s)" | awk -F":" {'print $2'}`
			echo $(($corespersocket * $threadspercore))
	    ;;
	    "arch")
			arch
	    ;;
	    *)
			echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
	;;
    "memory")
	case ${item} in
	    "total")
			memory=`cat /proc/meminfo | grep MemTotal: | awk {'print $2'}`
			echo $(($memory * 1024))
	    ;;
	    "freq")
			sudo dmidecode --type memory |grep "Speed:" |grep -v "Memory" |awk {'print $2'}
		;;
		"partnumber")
			sudo dmidecode --type memory |grep "Part Number" |awk {'print $3'}
		;;
		"manufacturer")
			sudo dmidecode --type memory |grep "Manufacturer" |awk {'print $2'}
		;;
		"capacity")
			sudo dmidecode --type memory |grep "Size:" |awk {'print $2*1024*1024'}
		;;
	    *)
			echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
	;;
    "storage")
	case ${item} in
	    "model")
			/bin/lsblk -io NAME,MODEL,TYPE -nl -s -d |grep -E "disk" |awk {'print $1"\t"$2'}
	    ;;
	    "disks")
			/bin/lsblk -io NAME,SIZE,TYPE -nl -s -d |grep -E "disk|crypt" |awk {'print $1"\t"$2'} 
	    ;;
	    "partitions")
			/bin/lsblk -io NAME,SIZE,TYPE -nl -s -d |grep -E "part|lvm|crypt" |awk {'print $1"\t"$2'}
	    ;;
	    *)
			echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
	;;
	"network")
	case ${item} in
	    "nic")
		#lshw -class network |grep product | awk -F": " {'print $2'}
			lspci | egrep -i 'network|ethernet' | awk -F": " {'print $2'}
	    ;;
	    "ipv4gateway")
			/sbin/ip route | grep default | awk {'print $3'}
	    ;;
	    "ipv6gateway")
			/sbin/ip -6 route show |grep default | awk {'print $3'}
	    ;;
	    "ipv4")
			/sbin/ip a | awk '  /inet / && !/127\.0\.0\.1/ {print $2}' | awk -F"/" {' print $1 '} 
	    ;;
	    "ipv6")
			/sbin/ip a | awk '  /inet6 / && !/::1\/128/ {print $2}' | awk -F"/" {' print $1 '} 
	    ;;
	    "extipv4")
			/usr/bin/curl -s -k -4 https://api.ipify.org;echo ""
	    ;;
	    "extipv6")
			/usr/bin/curl -s -k -6 https://api6.ipify.org; echo ""
	    ;;
	    *)
		echo "ZBX_NOTSUPPORTED"
	esac
	;;
    "os")
	case ${item} in
	    "desc")
			lsb_release -d | awk -F":" {'print $2'} | sed 's/\t//g'
	    ;;
	    "fulldesc")
			echo $(lsb_release -d | awk -F":" {'print $2'} | sed 's/\t//g'), $(lsb_release -r | awk -F":" {'print $2'} | sed 's/\t//g'), $(arch), $(lsb_release -c | awk -F":" {'print $2'} | sed 's/\t//g')
	    ;;
	    "version")
			lsb_release -r | awk -F":" {'print $2'} | sed 's/\t//g'
	    ;;
	    "guid"|"machineguid")
			guid=`sudo dmidecode -s system-uuid`
			if [[ -z ${guid} ]] ; then
				guid=`echo $(sudo dmidecode -t 4 | grep ID | sed 's/.*ID://;s/ //g') $(sudo lshw -quiet -C network |grep serial |awk {'print $2'} ) | md5sum | awk '{print $1}' | sed -e 's/^\(.\{8\}\)/\1-/'  -e 's/^\(.\{13\}\)/\1-/' -e 's/^\(.\{18\}\)/\1-/' -e 's/^\(.\{23\}\)/\1-/'`
			fi
			echo ${guid^^}

	    ;;
	    "installdate")
			sudo tune2fs -l $(df / |tail -1 | cut -f1 -d' ') | grep "Filesystem created:" |sed 's/Filesystem created:       //g'
		;;
	    "serial"|"productkey")
			echo "n/a"
	    ;;

	    *)
		echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
	;;
    
    "var")
	case ${item} in
	    "hostname")
			hostname
	    ;;
	    "fqdn")
			hostname -f
	    ;;
	    "domain")
			hostname -d
	    ;;
	    "vendor")
			sudo dmidecode -t bios | grep Vendor | awk -F": " {'print $2'}
	    ;;
	    "bios")
			sudo dmidecode -t bios | grep -E "Version|Release Date|BIOS Revision" | sed 's/\t//g'
	    ;;
	    "bitlocker")
			echo 'n/a'
	    ;;
	    "gfx")
			lspci -v | grep -i vga |awk -F"controller: " {'print $2'}
		;;
		"displays")
			xrandr --query | grep '\bconnected\b'
		;;
	    *)
			echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
	;;
	"identifier")
	case ${item} in
		"GetBiosId")
			sudo dmidecode -t bios |grep Version: |sed -e 's/\tVersion: //g'
		;;
		"GetProcessorIds")
			sudo lshw -C CPU -quiet |grep serial: |awk {'print $2'}
		;;
		"GetHddIds")
			sudo lshw -C disk -quiet |grep serial: |awk {'print $2'}	
		;;
		"GetMacAddresses")
			sudo lshw -C network -quiet |grep serial: |awk {'print $2'}
		;;

		*)
			echo "ZBX_NOTSUPPORTED"
		;;
	esac
	;;
	"serial")
	case ${item} in
		"display")
			echo "ZBX_NOTSUPPORTED"
		;;
		"bios")
			sudo dmidecode -t bios |grep Version: |sed -e 's/\tVersion: //g'
		;;
		"cpu")
			sudo lshw -C CPU -quiet |grep serial: |awk {'print $2'}
		;;
		"storage")
			sudo lshw -C disk -quiet |grep serial: |awk {'print $2'}	
		;;
		"chassis")
			sudo dmidecode -t chassis | grep "Serial Number:" |awk -F": " {'print $2'}
		;;
		"nic")
			sudo lshw -C network -quiet |grep serial: |awk {'print $2'}
		;;
		"memory")
			sudo lshw -C memory -quiet |grep serial: |awk {'print $2'}
		;;
		*)
			echo "ZBX_NOTSUPPORTED"
		;;
	esac
	;;
    "software")
	case ${item} in
	    "installed")
			case ${param} in
				"count")
					dpkg --get-selections |nl | tail -n1 |awk {'print $1'}
				;;				
				*)
					dpkg --get-selections
				;;
			esac
		
	    ;;
	    *)
			echo "ZBX_NOTSUPPORTED"
	    ;;
	esac
	;;
	*)
		echo "ZBX_NOTSUPPORTED"
	;;
esac

exit 0