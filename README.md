### Use Cloudflare Warp inside a Docker Container
Based on debian:stable-slim, use this image as you would debian:stable-slim
usage:
```Shell
docker run \
	--cap-add NET_ADMIN \
	-v /dev/net/tun:/dev/net/tun:ro \
	-it ethanscully/warp
```
