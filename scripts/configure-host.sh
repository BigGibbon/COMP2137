#!/bin/bash

# This ignores stop signals to avoid user error during script running
trap '' TERM HUP INT

# sets the flag defaults
verbose_flag="false"
ip_flag="false"
name_flag="false"
host_flag="false"

ip="NA_d"
name="NA_d"
host_ip="NA_d"
host_name="NA_d"


# this while loop goes through the arguments and sets the flags acording to what is given
while [ $# -gt 0 ]
do
	case $1 in
		"-verbose")
			# if the -verbose flag is found then set the verbose_flag variable to true
			verbose_flag="true"
			;;
		"-ip")
			# if the -ip flag is found, set the ip_flag variable to true, then it shifts the reader by one and takes that input as the ip
			ip_flag="true"
			shift
			ip="$1"
			;;
		"-name")
			# if the -name flag is found, set the name_flag variable to true, then it shifts the reader by one and takes that input as the name
			name_flag="true"
			shift
			name="$1"
			;;
		"-hostentry")
			# if the -hostentry flag is found, is sets the host_flag variable to true, then it shifts the reader by one and takes that input as the host_name, then does so again for the host_ip
			host_flag="true"
			shift
			host_name="$1"
			shift
			host_ip="$1"
			;;
		*)
			# if there is an invalid input on the command line we will treat it like a fatal error exits with an error code of 1
			exit 1
			;;
	esac
	shift
done

# run the -name logic if the conditions are met
if [[ "$name" != "NA_d" && "$name_flag" == "true" ]]; then
	# get both the live and persistant hostnames and assign them to variables
	live_hostname=$(hostname)
	static_hostname=$(cat /etc/hostname)

	if [[ "$live_hostname" != "$name" || "$static_hostname" != "$name" ]]; then
		hostnamectl set-hostname "$name"
		if [[ "$verbose_flag" == "true" ]]; then
			echo "running hostname updated for $name"
		fi
		logger "running hostname updated for $name"

		echo "$name" > /etc/hostname
		if [[ "$verbose_flag" == "true" ]]; then
			echo "/etc/hostname hostname updated for $name"
		fi
		logger "/etc/hostname hostname updated for $name"

		sed -i "s/$static_hostname/$name/g" /etc/hosts
		if [[ "$verbose_flag" == "true" ]]; then
			echo "/etc/hosts hostname updated for $name"
		fi
		logger "/etc/hosts hostname updated for $name"

	else
		if [[ "$verbose_flag" == "true" ]]; then
			echo "host name is already set to $name"
		fi
	fi
fi

# run the -ip logic if the conditions are met
if [[ "$ip" != "NA_d" && "$ip_flag" == "true" ]]; then
	current_ip=$(hostname -I | awk '{print $1}')
	netplan_path=$(ls /etc/netplan/*.yaml | head -n 1)

	if [[ "$current_ip" != "$ip" ]]; then
		sed -i "s/$current_ip/$ip/g" "$netplan_path"
		netplan apply
		if [[ "$verbose_flag" == "true" ]]; then
			echo "ip updated in $netplan_path"
		fi
		logger "ip updated in $netplan_path from $current_ip to $ip"

	if [[ "$current_ip" != "$ip" ]]; then
		sed -i "s/$current_ip/$ip/g" "/etc/hosts"
		if [[ "$verbose_flag" == "true" ]]; then
			echo "ip updated in /etc/hosts from $current_ip to $ip"
		fi
		logger "ip updated in /etc/hosts"

	else
		if [[ "$verbose_flag" == "true" ]]; then
			echo "ip address is already the same as the one given"
		fi
	fi
fi

# run the -hostentry logic if the conditions are met
if [[ "$host_flag" == "true" ]]; then

	if ! cat /etc/hosts | grep -q "$host_ip $host_name"; then
		echo "$host_ip $host_name" >> /etc/hosts
		if [[ "$verbose_flag" == "true" ]]; then
			echo "added host ip and name to the /etc/hosts file"
		fi
		logger "host ip and name added in /etc/hosts"

	else
		if [[ "$verbose_flag" == "true" ]]; then
			echo "host ip and name already found in /etc/hosts file"
		fi
	fi
fi
