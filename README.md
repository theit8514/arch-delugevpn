Deluge + OpenVPN + Privoxy
==========================

Deluge - http://deluge-torrent.org/
OpenVPN - https://openvpn.net/
Privoxy - http://www.privoxy.org/

Latest stable Deluge release for Arch Linux, including OpenVPN to tunnel torrent traffic securely (using iptables to block any traffic not bound for tunnel). This now also includes Privoxy to allow unfiltered http|https traffic via VPN.

**Pull image**

```
docker pull jbbodart/arch-delugevpn
```

**Run container**

```
docker run -d --cap-add=NET_ADMIN -p 8112:8112 -p 8118:8118 -p 2222:2222 --name=<container name> -v <path for data files>:/data -v <path for config files>:/config -v /etc/localtime:/etc/localtime:ro -e ENABLE_VPN=<yes|no> -e ENABLE_PRIVOXY=<yes|no> -e ENABLE_SSHD=<yes|no> -e DELUGE_LISTEN_PORT=<port no> jbbodart/arch-delugevpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access Deluge**

```
http://<host ip>:8112
```

Default password for the webui is "deluge"

**Access Privoxy**

```
<host ip>:8118
```

Default is no authentication required

**Access inside container with SSH**

```
ssh -p 2222 root@<host ip>
```

No password required

***OpenVPN Setup***

1. Start the delugevpn docker to create the folder structure
2. Stop delugevpn docker and copy your .ovpn file in the /config/openvpn/ folder on the host
3. Start delugevpn docker
4. Check supervisor.log to make sure you are connected to the tunnel

**Example**

```
docker run -d --cap-add=NET_ADMIN -p 8112:8112 -p 8118:8118 -p 2222:2222 --name=DelugeVPN -v /docker/DelugeVPN/data:/data -v /docker/DelugeVPN/config:/config -v /etc/localtime:/etc/localtime:ro -e ENABLE_VPN=yes -e ENABLE_PRIVOXY=yes -e ENABLE_SSHD=yes -e DELUGE_LISTEN_PORT=49313 jbbodart/arch-delugevpn
```
