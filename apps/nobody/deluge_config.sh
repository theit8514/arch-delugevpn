#!/bin/bash

echo "[info] waiting for deluge to start up..."

# wait for deluge daemon process to start (listen for port)
while [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".58846"') == "" ]]; do
	sleep 0.5
done

echo "[info] deluge started, starting configuration"

if [[ $DELUGE_INCOMING_PORT =~ ^-?[0-9]+$ ]]; then
	echo "[info] configuring Deluge listen port..."
	# enable bind incoming port to specific port (disable random)
	/usr/bin/deluge-console -c /config/deluge "config --set random_port False"
	# set incoming port
	/usr/bin/deluge-console -c /config/deluge "config --set listen_ports ($DELUGE_INCOMING_PORT,$DELUGE_INCOMING_PORT)"
fi

echo "[info] configuring Deluge data dirs..."

/usr/bin/deluge-console -c /config/deluge "config --set move_completed_path /data/Seeding"
/usr/bin/deluge-console -c /config/deluge "config --set download_location /data/Downloads"
/usr/bin/deluge-console -c /config/deluge "config --set torrentfiles_location /data/Torrents"
/usr/bin/deluge-console -c /config/deluge "config --set autoadd_location /data/Torrents"

echo "[info] deluge configuration completed"
