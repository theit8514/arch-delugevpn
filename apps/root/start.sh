#!/bin/bash

# exit script if return code != 0
set -e

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

# set up timezone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

# set up sshd
#############

if [[ "${ENABLE_SSHD}" == "yes" ]]; then

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

    echo "[info] OpenSSH server configuration done"
fi

# set up openvpn
################

if [[ "${ENABLE_VPN}" == "yes" ]]; then
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

    echo "[info] OpenVPN configuration done"

fi

# set up privoxy
################

if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then	
	echo "[info] Configuring Privoxy"...
	mkdir -p /config/privoxy
		
	if [[ ! -f "/config/privoxy/config" ]]; then
		cp -R /etc/privoxy/ /config/
	fi
		
	LAN_IP=$(hostname -i)
	sed -i -e "s/confdir \/etc\/privoxy/confdir \/config\/privoxy/g" /config/privoxy/config
	sed -i -e "s/logdir \/var\/log\/privoxy/logdir \/config\/privoxy/g" /config/privoxy/config
	sed -i -e "s/listen-address.*/listen-address  $LAN_IP:8118/g" /config/privoxy/config

	echo "[info] Privoxy configuration done"
fi


# start everything
##################

if [[ "${ENABLE_SSHD}" == "yes" ]]; then
    echo "[info] Starting OpenSSH daemon..."
    supervisorctl start sshd
fi

if [[ "${ENABLE_VPN}" == "yes" ]]; then    
    echo "[info] Starting OpenVPN..."
    supervisorctl start openvpn
fi

if [[ "${ENABLE_PRIVOXY}" == "yes" ]]; then
    echo "[info] Starting Privoxy..."
    supervisorctl start privoxy
fi

echo "[info] Starting Deluge..."
supervisorctl start deluge
echo "[info] Configuring Deluge..."
supervisorctl start deluge_config
echo "[info] Starting Deluge GUI..."
supervisorctl start deluge_gui
if [[ "${ENABLE_VPN}" == "yes" ]]; then  
	echo "[info] Starting VPN IP monitoring..."
	supervisorctl start deluge_setip
fi
