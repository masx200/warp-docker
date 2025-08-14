#!/bin/bash
# dependencies  // stole from https://github.com/cmj2002/warp-docker/
if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi
mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
    rm /run/dbus/pid
fi
dbus-daemon --config-file=/usr/share/dbus-1/system.conf
# Setup Logs
mkdir -p /var/log/warp
# Start Warp Service
warp-svc > /var/log/warp/svc.log 2> /var/log/warp/svc-err.log &
# Register to Warp
while :; do
    warp-cli --accept-tos registration new >> /var/log/warp/cli.log 2>> /var/log/warp/cli-err.log
    if [ $? -eq 0 ]; then
        break
    fi
    sleep .1
done
# Connect to Warp
while :; do
    warp-cli --accept-tos connect >> /var/log/warp/cli.log 2>> /var/log/warp/cli-err.log
    if [ $? -eq 0 ]; then
        break
    fi
    sleep .1
done
# Wait for VPN to fully start
while true; do
    code=$(curl -s -o /dev/null -w "%{http_code}" http://1.1.1.1/)
    if [ "$code" -eq 301 ]; then
        break
    fi
    sleep 0.1
done
# Transfer Control to CMD
if [ -z "$1" ]; then
    exec bash
else
    exec "$@"
fi
