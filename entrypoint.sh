#!/bin/bash
warp-svc >/dev/null 2>&1 &
while :; do
    warp-cli --accept-tos registration new >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 1
done
while :; do
    warp-cli --accept-tos connect >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 1
done
entry
if [ -z "$1" ]; then
    bash
else
    exec "$@"
fi
