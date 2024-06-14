#!/bin/bash
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
# Start Go Program
entry
# Transfer Control to CMD
if [ -z "$1" ]; then
    exec bash
else
    exec "$@"
fi
