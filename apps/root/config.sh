#!/bin/bash

# set up config directory
#########################

mkdir -p /config/openvpn
mkdir -p /config/privoxy
mkdir -p /config/deluge

chown -R nobody:users /config/privoxy /config/deluge
#chmod -R 775 /config/privoxy /config/deluge

# set up data directory
#########################

mkdir -p /data/Downloads
mkdir -p /data/Torrents
mkdir -p /data/Seed
mkdir -p /data/Watch

chown -R nobody:users /data/Downloads /data/Torrents /data/Seed /data/Watch
