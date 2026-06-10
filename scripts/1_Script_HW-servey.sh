#!/bin/bas

# Place the current date in the formate of YYYY-MM-DD into a variable called DATE_NOW via the data command to be printed in the report
DATE_NOW=$(date +"%Y-%m-%d")

# This gets the distrobution name and places it into a variable called DISTRO_NAME to be printed in the report
DISTRO_NAME=$(source /etc/os-release; echo $NAME)

# This gets the distrobution version and places it into a variable called DISTRO_VERSION to be printed in the report
DISTRO_VERSION=$(source /etc/os-release; echo $VERSION)

# This gets the uptime and places it into a variable called UPTIME to be printed in the report
UPTIME=$(uptime)

# This gets the CPU make and model and puts it into a variable called CPU_INFO to be printed in the report
# it does this by first listing the CPU section of lshw, then it uses grep to find only the product lines (of which there are multiple),
# then it uses awk to grab only the first line of the product lines (i have multiple) from grep (all of which are duplicates),
# in that same awk replaces the first word (which is the "product:" that grep found) with a blank (""),
# and lastly does a print so that the output can be placed into the MODEL variable. Same with the MAKE variable, but we use vendor.
# then that gets echo'd out to the CPU_INFO var
CPU_INFO=$(MODEL=$(lshw -C cpu | grep product | awk 'NR==1 { $1=""; print }')
	   MAKE=$(lshw -C cpu | grep vendor | awk 'NR==1 { $1=""; print }')
	   echo $MAKE $MODEL)

# THIS gets the RAM size and places it into a variable called RAM_SIZE to be printed in the report later
# the process of getting the ram size is nearly identical to the CPU info exept we look for the memory section of lshw and we grep for size
RAM_SIZE=$(lshw -C memory | grep size | awk 'NR==1 { $1=""; print }')

#This gets the disks name, model, and size and places it intoa variable called DISKS to be printed in the report
# This get the only the entries from lsblk of the type disk, displays only the name, model, and size
# it then uses awk to replace all the \x20 (escape code for space which gets put in the output for some reason) with a space (" ")
DISKS=$(lsblk --raw -o NAME,MODEL,SIZE -nQ 'TYPE == "disk"' | awk '{gsub(/\\x20/, " "); print}')

# This gets the video card make and model and places it into the VIDEO variable to be printed in the report
# refer to the CPU_INFO comments for a break down of what is happening as it is the same, just in the video section not the cpu section
VIDEO=$(MODEL=$(lshw -C video | grep product | awk 'NR==1 { $1=""; print }') 
        MAKE=$(lshw -C video | grep vendor | awk 'NR==1 { $1=""; print }') 
        echo $MAKE $MODEL)

# This gets the host ip address connected to the default gateway and puts it into the HOST_ADDR varaible to be printed in the report
HOST_ADDR=$(ip route | grep default | awk '{print $9}')

# Uses ip route to get info about the route to the default gateway. greps for the word default to find the line where the default gatway IP is, 
# then uses awk to print the default gateway IP
DEFAULT_GATE=$(ip route | grep default | awk '{print $3}')

# uses resolvectl status to get info pertaining to DNS. Then uses grep to find the line pertaining to current DNS server. Then uses awk to grab only the IP of the DNS
DNS_SERVER=$(resolvectl status | grep "Current DNS Server:" | awk '{print $4}')

# uses w with flags piped into awk to grab only the firt word fo each line (which is the user).
# then that is piped to paste with flags which replaces the newlines with commas thus giving us a comma seperated list of users
USERS=$(w -hs | awk '{print $1}' | paste -sd , -)

# This gets the mount point and avalible disk space using df with filters, then awk is used to take the first line (which is the header) off leaving us with the
# desired result
DISK_SPACE=$(df -h --output='target','avail' | awk 'NR>1')

# This gets the process count which returns one process per line, and then uses word count with the line flag to count the lines and thus processes.
# sudo is used to count the hidden processes
PROC_COUNT=$(sudo ps -e --no-headers | wc -l)

# This gets the three load averages using uptime. It is done in a slightly complicated way of grabing the last three words of the line.
# It is done this way as i did not know if uptime always produces the same amount of words or not, but i do know the last three words are always the load averages
LOAD_AVGS=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')

# This gets the ports (i use -t to filter only for TCP ports, since they are the only network ports that can have a listed status of LISTEN) that are listening.
# it uses ss with flags to get just the TCP ports that are listening,
# then that is piped to awk which finds and substitutes the forth word (which is a IP:PORT) down to just a port number,
# then passes that list of numbers off to sort with flags which gets rid of the duplicates (needed as often there is a IPv4 and IPv6 listening on the same port),
# then paste is used as before to turn it into a comma seperated list
LISTEN_PORTS=$(ss -tlnH | awk '{sub(/.*:/, "", $4); print $4}' | sort -nu | paste -sd , -)

# This gets the status of UFW which returns status: STATUS, so we use awk to take the status: off leaving us with the STATUS, which is what we want
UFW_STATUS=$(sudo ufw status | awk '{print $2}')

# This is just a clear to make sure that this is the only thing on screen
clear
# this prints a system report using the variables made earlier to print data dynamically
cat << EOF
System Report for $HOSTNAME generated by $USER, on $DATE_NOW

System Information
------------------
OS: $DISTRO_NAME $DISTRO_VERSION
Uptime: $UPTIME
CPU: $CPU_INFO
RAM: $RAM_SIZE
Disk(s): $DISKS
Video: $VIDEO
Host Address: $HOST_ADDR
Gateway IP: $DEFAULT_GATE
DNS Server: $DNS_SERVER

System Status
-------------
Users Logged In: $USERS
Disk Space: $DISK_SPACE
Process Count: $PROC_COUNT
Load Averages: $LOAD_AVGS
Listening Network Ports: $LISTEN_PORTS
UFW Status: $UFW_STATUS

EOF
