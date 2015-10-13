#!/bin/bash

if [[ $VPN_ENABLED == "no" ]]; then
	echo "[info] VPN disabled, skipping configuration of deluge listen interface..."
	exit 0
fi

echo "[info] configuring Deluge listen interface..."

echo "[info] VPN enabled, waiting for tun0 interface to come up..."
# run script to check ip is valid for tun0
source /home/nobody/checkip.sh

# wait for deluge daemon process to start (listen for port)
while [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".58846"') == "" ]]; do
	sleep 0.5
done

# while loop to check interface IP every 5 mins
while true
do
	# get currently allocated ip address for adapter tun0
	LOCAL_IP=`ifconfig tun0 2>/dev/null | grep 'inet' | grep -P -o -m 1 '(?<=inet\s)[^\s]+'`
	
	# query deluge for current ip for tunnel
	LISTEN_INTERFACE=`/usr/bin/deluge-console -c /config/deluge "config listen_interface" | grep -P -o -m 1 '[\d\.]+'`

	# if current listen interface ip is different to tunnel local ip then re-configure deluge
	if [[ $LISTEN_INTERFACE != "$LOCAL_IP" ]]; then
		echo "[info] Deluge listening interface IP $LISTEN_INTERFACE and OpenVPN local IP $LOCAL_IP different, configuring Deluge..."

		# set listen interface to tunnel local ip
		/usr/bin/deluge-console -c /config/deluge "config --set listen_interface $LOCAL_IP"
	fi

	sleep 5m

done
