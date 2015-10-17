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

# set up DNS
# add in OpenNIC public nameservers
echo 'nameserver 192.71.249.83' > /etc/resolv.conf
echo 'nameserver 87.98.175.85' >> /etc/resolv.conf
echo 'nameserver 92.222.80.28' >> /etc/resolv.conf
echo 'nameserver 5.135.183.146' >> /etc/resolv.conf


# set up sshd
#############

if [[ "${SSHD_ENABLED}" == "yes" ]]; then

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

# set up openvpn
################

if [[ "${VPN_ENABLED}" == "yes" ]]; then
    echo "[info] Configuring OpenVPN client..."
    # wildcard search for openvpn config files
    VPN_CONFIG=$(find /config/openvpn -maxdepth 1 -name "*.ovpn" -print)
        
    if [[ -z "${VPN_CONFIG}" ]]; then
	    echo "[crit] Missing OpenVPN configuration file in /config/openvpn/ (no files with an ovpn extension exist)"
	    echo "[crit] Please create and restart container"
	    exit 1
    fi
        
    # chek for kernel modules
    for i in "tun" "xt_mark" "iptable_mangle" ; do
        if [[ $(lsmod | awk -v module="$i" '$1==module {print $1}' | wc -l) -eq 0 ]] ; then
            echo "[crit] Missing $i kernel module. Please insmod and restart container"
            exit 1
        fi
    done
        
    # remove ping and ping-restart from ovpn file if present, now using flag --keepalive
    if $(grep -Fq "ping" "${VPN_CONFIG}"); then
	    sed -i '/ping.*/d' "${VPN_CONFIG}"
    fi
        
    # read port number and protocol from ovpn file (used to define iptables rule)
    VPN_PORT=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '^remote\s[^\r\n]+' | grep -P -o -m 1 '[\d]+$')
    VPN_PROTOCOL=$(cat "${VPN_CONFIG}" | grep -P -o -m 1 '(?<=proto\s)[^\r\n]+')

    # create the tunnel device
    [ -d /dev/net ] || mkdir -p /dev/net
    [ -c /dev/net/tun ] || mknod /dev/net/tun c 10 200

    # get ip for local gateway (eth0)
    DEFAULT_GATEWAY=$(ip route show default | awk '/default/ {print $3}')
    
    # setup ip tables and routing for application
    source /root/iptables.sh

    echo "[info] OpenVPN client configuration done, starting OpenVPN..."
    supervisorctl start openvpn
fi
