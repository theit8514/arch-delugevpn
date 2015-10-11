#!/bin/bash

mkdir -p /config/openvpn
mkdir -p /config/privoxy
mkdir -p /config/deluge

chown -R nobody:users /config/privoxy /config/deluge
chmod -R 775 /config/privoxy /config/deluge

