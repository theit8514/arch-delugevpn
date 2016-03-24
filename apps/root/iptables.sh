#!/bin/bash

# setup route for deluge webui using set-mark to route traffic for port 8112 to eth0
echo "8112    webui" >> /etc/iproute2/rt_tables
ip rule add fwmark 1 table webui
ip route add default via $DEFAULT_GATEWAY table webui

# setup route for privoxy using set-mark to route traffic for port 8118 to eth0
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	echo "8118    privoxy" >> /etc/iproute2/rt_tables
	ip rule add fwmark 2 table privoxy
	ip route add default via $DEFAULT_GATEWAY table privoxy
fi

# setup route for sshd using set-mark to route traffic for port 2222 to eth0
if [[ $ENABLE_SSHD == "yes" ]]; then
	echo "2222    sshd" >> /etc/iproute2/rt_tables
	ip rule add fwmark 3 table sshd
	ip route add default via $DEFAULT_GATEWAY table sshd
fi

echo "[info] ip routing table"
ip route
echo "--------------------"

# input iptable rules
###

INTERFACES=$(ip link show type veth | grep "^[0-9]" | awk '{ print substr($2, 1, length($2) - 1); }')

# set policy to drop for input
iptables -P INPUT DROP

# accept input to tunnel adapter
iptables -A INPUT -i tun0 -j ACCEPT

# accept input to/from docker containers (172.x range is internal dhcp)
iptables -A INPUT -s 172.17.0.0/16 -d 172.17.0.0/16 -j ACCEPT

for i in $INTERFACES; do

	# accept input from ip range on lan (if specified)
	if [[ ! -z "${LAN_RANGE}" ]]; then
		iptables -A INPUT -i $i -m iprange --src-range $LAN_RANGE -j ACCEPT
	fi

	# accept input to vpn gateway
	iptables -A INPUT -i $i -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT

	# accept input to deluge webui port 8112
	iptables -A INPUT -i $i -p tcp --dport 8112 -j ACCEPT
	iptables -A INPUT -i $i -p tcp --sport 8112 -j ACCEPT

	# accept input to privoxy port 8118 if enabled
	if [[ $ENABLE_PRIVOXY == "yes" ]]; then
		iptables -A INPUT -i $i -p tcp --dport 8118 -j ACCEPT
		iptables -A INPUT -i $i -p tcp --sport 8118 -j ACCEPT
	fi

	if [[ $ENABLE_SSHD == "yes" ]]; then
		iptables -A INPUT -i $i -p tcp --dport 2222 -j ACCEPT
		iptables -A INPUT -i $i -p tcp --sport 2222 -j ACCEPT
	fi

done

# accept input dns lookup
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# accept input icmp (ping)
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# accept input to local loopback
iptables -A INPUT -i lo -j ACCEPT

# output iptable rules
###

# set policy to drop for output
iptables -P OUTPUT DROP

# accept output from tunnel adapter
iptables -A OUTPUT -o tun0 -j ACCEPT

for i in $INTERFACES; do

	# accept output to/from docker networks
	NETWORK=$(ip route | grep "dev $i" | grep "scope link" | awk '{ print $1 }')
	if [[ ! -z "${NETWORK}" ]]; then
		iptables -A OUTPUT -s $NETWORK -d $NETWORK -j ACCEPT
	fi

	# accept output to ip range on lan (if specified)
	if [[ ! -z "${LAN_RANGE}" ]]; then
		iptables -A OUTPUT -o $i -m iprange --dst-range $LAN_RANGE -j ACCEPT
	fi

	# accept output from vpn gateway
	iptables -A OUTPUT -o $i -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT

	# accept output from deluge webui port 8112 (used when tunnel down)
	iptables -A OUTPUT -o $i -p tcp --dport 8112 -j ACCEPT
	iptables -A OUTPUT -o $i -p tcp --sport 8112 -j ACCEPT

done

# accept output from deluge webui port 8112 (used when tunnel up)
iptables -t mangle -A OUTPUT -p tcp --dport 8112 -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p tcp --sport 8112 -j MARK --set-mark 1

# accept output to privoxy port 8118 if enabled
if [[ $ENABLE_PRIVOXY == "yes" ]]; then
	iptables -t mangle -A OUTPUT -p tcp --dport 8118 -j MARK --set-mark 2
	iptables -t mangle -A OUTPUT -p tcp --sport 8118 -j MARK --set-mark 2
fi

# accept output to sshd port 2222 if enabled
if [[ $ENABLE_SSHD == "yes" ]]; then
	iptables -t mangle -A OUTPUT -p tcp --dport 2222 -j MARK --set-mark 3
	iptables -t mangle -A OUTPUT -p tcp --sport 2222 -j MARK --set-mark 3
fi
# accept output for dns lookup
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# accept output for icmp (ping)
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# accept output from local loopback
iptables -A OUTPUT -o lo -j ACCEPT

echo "[info] iptables"
iptables -S
echo "--------------------"
