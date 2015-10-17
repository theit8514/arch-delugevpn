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

mkdir -p /data/downloads
mkdir -p /data/torrents
mkdir -p /data/seed
mkdir -p /data/watch

chown -R nobody:users /data/Downloads /data/Torrents /data/Seed /data/Watch

# set up sshd
#############

if [[ $SSHD_ENABLED == "yes" ]]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
fi


