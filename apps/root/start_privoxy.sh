#!/bin/bash

if [[ $ENABLE_PRIVOXY == "yes" ]]; then	
    /usr/bin/privoxy --no-daemon /config/privoxy/config
fi
