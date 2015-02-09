FROM binhex/arch-base:2015020300
MAINTAINER binhex

# additional files
##################

# add supervisor conf file for app
ADD delugevpn.conf /etc/supervisor/conf.d/delugevpn.conf

# add bash script to create tun adapter, setup ip route and create vpn tunnel
ADD start.sh /root/start.sh

# add bash script to run deluge daemon
ADD apps/deluge.sh /home/nobody/deluge.sh

# add bash script to run deluge webui
ADD apps/webui.sh /home/nobody/webui.sh

# add pia certificates
ADD config/ca.crt /root/ca.crt

# add pia certificates
ADD config/crl.pem /root/crl.pem

# add pia config file (netherlands)
ADD config/openvpn.conf /root/openvpn.conf

# install app
#############

# install install app using pacman, set perms, cleanup
RUN pacman -Sy --noconfirm && \
	pacman -S net-tools openvpn unzip unrar librsvg pygtk python2-service-identity python2-mako python2-notify deluge --noconfirm && \
	chmod +x /root/start.sh /home/nobody/deluge.sh /home/nobody/webui.sh && \
	chown -R nobody:users /usr/bin/deluged /usr/bin/deluge-web && \
	chmod -R 775 /usr/bin/deluged /usr/bin/deluge-web && \
	yes|pacman -Scc && \	
	rm -rf /usr/share/locale/* && \
	rm -rf /usr/share/man/* && \
	rm -rf /tmp/*

# docker settings
#################

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /data to host defined data path (used to store data from app)
VOLUME /data

# expose port for http
EXPOSE 8112

# expose port for deluge daemon
EXPOSE 58846

# expose port for incoming torrent data (tcp and udp)
EXPOSE 58946
EXPOSE 58946/udp

# set environment variables for user nobody
ENV HOME /home/nobody

# set environment variable for terminal
ENV TERM xterm

# run supervisor
################

# run supervisor
CMD ["supervisord", "-c", "/etc/supervisor.conf", "-n"]