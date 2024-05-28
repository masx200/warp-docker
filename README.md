### Use Cloudflare Warp inside a Docker Container
usage:
```Shell
docker run \
	--cap-add NET_ADMIN \
	-v /dev/net/tun:/dev/net/tun:ro \
	-it ethanscully/warp
```