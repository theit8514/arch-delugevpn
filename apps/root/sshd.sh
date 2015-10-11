
#!/bin/bash

# if SSHD_ENABLED set to "no" then don't run OpenSSH Server
if [[ $SSHD_ENABLED == "no" ]]; then

        echo "[info] SSHD not enabled, not starting OpenSSH server"

else

        echo "[info] SSHD is enabled, starting OpenSSH server"

        echo "[info] Configuring OpenSSH server..."

        mkdir -p /root/.ssh
        chmod 700 /root/.ssh

        if [[ ! -f "/config/sshd/authorized_keys" ]]; then
                cp -R /config/sshd/authorized_keys /root/.ssh/
                chmod 600 /root/.ssh/*
        fi

        LAN_IP=$(hostname -i)
        sed -i -e "s/#ListenAddress.*/ListenAddress $LAN_IP/g" /etc/ssh/sshd_config
        sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config
        sed -i -e "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
        sed -i -e "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
        sed -i -e "s/#PermitEmptyPasswords.*/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config
        sed -i -e "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

        echo "[info] Config done, starting OpenSSH server..."

        /usr/sbin/sshd -D

fi
