#!/bin/bash

if [[ $SSHD_ENABLED == "yes" ]]; then
        /usr/sbin/sshd -D
fi
