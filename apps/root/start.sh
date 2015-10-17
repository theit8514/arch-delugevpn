#!/bin/bash

# set up config directory
#########################

echo "[info] Creating config directories..."
 
mkdir -p /config/openvpn
mkdir -p /config/privoxy
mkdir -p /config/deluge

chown -R nobody:users /config/privoxy /config/deluge
#chmod -R 775 /config/privoxy /config/deluge

# set up data directory
#########################

echo "[info] Creating data directories..."
mkdir -p /data/downloads
mkdir -p /data/torrents
mkdir -p /data/seed
mkdir -p /data/watch

chown -R nobody:users /data/Downloads /data/Torrents /data/Seed /data/Watch

# set up sshd
#############

if [[ $SSHD_ENABLED == "yes" ]]; then

        echo "[info] Configuring OpenSSH sever..."
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh

        if [[ -f "/config/sshd/authorized_keys" ]]; then
                cp -R /config/sshd/authorized_keys /root/.ssh/ && chmod 600 /root/.ssh/*
        fi

        LAN_IP=$(hostname -i)
        sed -i -e "s/#ListenAddress.*/ListenAddress $LAN_IP/g" /etc/ssh/sshd_config
        sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config
        sed -i -e "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
        sed -i -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
        sed -i -e "s/#PermitEmptyPasswords.*/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config
        sed -i -e "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

        echo "[info] OpenSSH configuration done, starting OpenSSH daemon..."
        supervisorctl start sshd
fi



