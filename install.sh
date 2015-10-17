#!/bin/bash

# exit script if return code != 0
set -e

# define pacman packages
pacman_packages="net-tools openresolv unzip unrar librsvg pygtk python2-service-identity python2-mako python2-notify openvpn privoxy deluge openssh"

# install pre-reqs
pacman -Sy --noconfirm
pacman -S --needed $pacman_packages --noconfirm

# set permissions
chown -R nobody:users /home/nobody /usr/bin/privoxy /etc/privoxy /usr/bin/deluged /usr/bin/deluge-web
chmod -R 775 /home/nobody /usr/bin/privoxy /etc/privoxy /usr/bin/deluged /usr/bin/deluge-web

# set up openssh
mkdir /var/run/sshd
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown -Rf root:root /root/.ssh
# generate host keys
/usr/bin/ssh-keygen -A

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
