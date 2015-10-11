#!/bin/bash

echo "[info] configuring Deluge listen port..."

# wait for deluge daemon process to start (listen for port)
while [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".58846"') == "" ]]; do
	sleep 0.1
done

CURRENT_DELUGE_INCOMING_PORT=`/usr/bin/deluge-console -c /config/deluge "config listen_ports" | grep -P -o -m 1 '[\d]+(?=\,)'`
echo "[info] Current Deluge incoming port $DELUGE_INCOMING_PORT"

if [[ $DELUGE_INCOMING_PORT =~ ^-?[0-9]+$ ]]; then
	if [[ "$CURRENT_DELUGE_INCOMING_PORT" != "$DELUGE_INCOMING_PORT" ]]; then
		# enable bind incoming port to specific port (disable random)
		/usr/bin/deluge-console -c /config/deluge "config --set random_port False"

		# set incoming port
		/usr/bin/deluge-console -c /config/deluge "config --set listen_ports ($$DELUGE_INCOMING_PORT,$$DELUGE_INCOMING_PORT)"
	fi
else
	echo "[warn] DELUGE_INCOMING_PORT incoming port is not an integer. Skipping Deluge listen port configuration"
fi

CURRENT_DELUGE_INCOMING_PORT=`/usr/bin/deluge-console -c /config/deluge "config listen_ports" | grep -P -o -m 1 '[\d]+(?=\,)'`
echo "[info] New Deluge incoming port $DELUGE_INCOMING_PORT"
