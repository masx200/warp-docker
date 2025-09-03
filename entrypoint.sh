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
while :; do
    warp-cli --accept-tos status >> /var/log/warp/cli.log 2>> /var/log/warp/cli-err.log
    if [ $? -eq 0 ]; then
        break
    fi
    sleep .1
done


warp-cli --accept-tos mode warp+doh >> /var/log/warp/cli.log 2>> /var/log/warp/cli-err.log
# 现在由于wireguard被qos,只能使用masque协议,新版本使用的默认协议为wireguard,版本号是2025.6.1335.0
warp-cli --accept-tos tunnel protocol set MASQUE >> /var/log/warp/cli.log 2>> /var/log/warp/cli-err.log



warp-cli --accept-tos registration delete >> /var/log/warp/cli.log 2>> /var/log/warp/cli-err.log

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
# Wait for zero trust to fully start
while true; do
    code=$(curl -s -o /dev/null -w "%{http_code}"  --http2 https://www.cloudflare.com   --max-time 10  --connect-timeout 10)
    if [ "$code" -eq 200 ]; then
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
