### Use Cloudflare Warp inside a Docker Container
Based on debian:stable-slim, use this image as you would debian:stable-slim

usage:
```Shell
docker run \
    --cap-add NET_ADMIN \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    -it ethanscully/warp
```
