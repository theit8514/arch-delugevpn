#!/bin/bash

echo "[info] starting Deluge..."

if [[ -f /config/deluge/core.conf ]]; then
	# reset listen interface ip address for deluge
	sed -i -e 's/"listen_interface".*/"listen_interface": "",/g' /config/deluge/core.conf
fi

if [[ $VPN_ENABLED == "yes" ]]; then
	echo "[info] VPN enabled, waiting for tun0 interface to come up..."
	# run script to check ip is valid for tun0
	source /home/nobody/checkvpn.sh
fi

echo "[info] All checks complete, starting Deluge daemon..."

# run deluge daemon
/usr/bin/deluged -d -c /config/deluge -L info -l /config/deluge/deluged.log
