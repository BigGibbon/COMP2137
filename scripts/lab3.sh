#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file
﻿
verbose_opt=""

if [[ "$1" == "-verbose" ]]; then
	verbose_opt="-verbose"
fi

scp configure-host.sh remoteadmin@server1-mgmt:/root

if [ $? -eq 0 ]; then
	ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 $verbose_opt
	if [ $? -ne 0 ]; then
		echo "failed to run configure-host.sh on server 1"
		exit 1
	fi
else
	echo "Failed to copy configure-host.sh to server 1"
	exit 1
fi

scp configure-host.sh remoteadmin@server2-mgmt:/root
if [ $? -eq 0 ]; then
	ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 $verbose_opt
	if [ $? -ne 0 ]; then
		echo "failed to run configure-host.sh on server 2"
		exit 2
	fi
else
	echo "Failed to copy configure-host.sh to server 2"
	exit 2
fi

./configure-host.sh -hostentry loghost 192.168.16.3 $verbose_opt
if [ $? -ne 0 ]; then
	echo "failed to run configure-host.sh on host"
	exit 3
fi

./configure-host.sh -hostentry webhost 192.168.16.4 $verbose_opt
if [ $? -ne 0 ]; then
	echo "failed to run configure-host.sh on host"
	exit 4
fi



