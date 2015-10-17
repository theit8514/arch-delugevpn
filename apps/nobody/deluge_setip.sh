#!/bin/bash

echo "[info] configuring Deluge listen interface..."

while true ; do
	# run script to check VPN is up
	source /home/nobody/checkvpn.sh
		
	# wait for deluge daemon process to start (listen for port)
	while [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".58846"') == "" ]]; do
		sleep 1
	done

	LOCAL_IP=$(ip addr | awk '/inet/ && /tun0/{sub(/\/.*$/,"",$2); print $2}')
	# query deluge for current ip for tunnel
	LISTEN_INTERFACE=$(/usr/bin/deluge-console -c /config/deluge "config listen_interface" | grep -P -o -m 1 '[\d\.]+')
	# if current listen interface ip is different to tunnel local ip then re-configure deluge
	if [[ "${LISTEN_INTERFACE}" != "${LOCAL_IP}" ]]; then
		echo "[info] VPN IP changed. Re-configuring Deluge..."
		# set listen interface to tunnel local ip
		/usr/bin/deluge-console -c /config/deluge "config --set listen_interface ${LOCAL_IP}"
	fi
	sleep 1m
done
