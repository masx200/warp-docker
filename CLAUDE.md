# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

This is a Docker-based implementation of Cloudflare WARP client that provides
secure zero trust connectivity and HTTP proxy services. The project consists of
two main services integrated via Docker Compose:

1. **HTTP Proxy Server** - Go-based HTTP/HTTPS proxy with DoH (DNS over HTTPS)
   integration
2. **WARP Docker Container** - Cloudflare WARP client running MASQUE protocol to
   avoid WireGuard QoS limitations

## Common Development Commands

### Docker Operations

- **Build Docker image**:
  `docker build -f dockerfile -t "docker.cnb.cool/masx200/docker_mirror/warp-docker:latest" .`
- **Build using script**: `./build.sh` (requires execute permissions)
- **Start services**: `docker-compose up -d`
- **Stop services**: `docker-compose down`
- **View all logs**: `docker-compose logs -f`
- **View specific service logs**: `docker-compose logs -f warp-docker` or
  `docker-compose logs -f http-proxy-go-server`
- **Monitor WARP status**: View running container logs or exec into container to
  run `warp-cli --accept-tos --json --verbose status`

### Development Setup

- **Setup TUN device**: Container auto-creates `/dev/net/tun` but manual
  creation may be needed on host:
  `mkdir -p /dev/net && mknod /dev/net/tun c 10 200 && chmod 600 /dev/net/tun`
- **Network configuration**: Uses external `dpanel-network` with IPAM config for
  IPv4 (`172.31.123.0/24`) and IPv6 (`fd12:5687:4425:5555::/64`)

## Architecture Overview

### Service Components

**HTTP Proxy Server (`http-proxy-go-server`)**:

- Port: 58877 (HTTP/HTTPS proxy)
- Credentials: admin (user), configurable password via `${password}` env var
- DoH servers: Custom server + Cloudflare's 1.1.1.1 with h2/h3 support
- Image: `docker.cnb.cool/masx200/docker_mirror/http-proxy-go-server:2.6.0`
- Built with Go 1.24.4, supports HTTP/2 and HTTP/3

**WARP Container (`warp-docker`)**:

- Base image: Modified Cloudflare WARP container with custom APT sources
- Key capabilities: `NET_ADMIN`, `MKNOD`, `AUDIT_WRITE`
- Devices: `/dev/net/tun` for VPN tunnel
- Protocol: MASQUE (configured automatically to avoid WireGuard QoS)
- Mode: `warp+doh` with automatic registration
- Logs stored in `/var/log/warp/` directory

**Curl Monitor (`curl-monitor`)**:

- Automated connectivity testing every 60 seconds
- Uses HTTP/2 to test proxy functionality with Google
- Runs as privileged user for network testing

### Entry Point Flow (`entrypoint.sh`)

1. Create TUN device if missing
2. Start D-Bus service (required for WARP)
3. Initialize logging directories
4. Start WARP service in background
5. Wait for WARP service to be ready (registration loop)
6. Set protocol to MASQUE (avoid WireGuard QoS)
7. Register new WARP device (delete old registration first)
8. Connect to WARP network
9. Wait for Cloudflare connectivity verification
10. Transfer control to command or start status monitor

## Key Configuration Files

### `docker-compose.yml`

- Uses external `dpanel-network` with custom IPAM
- Three services: proxy, WARP client, and monitoring
- Environment variable `${password}` for proxy authentication
- Logging configuration with 100MB max size, 5 file rotation

### `dockerfile`

- Based on Cloudflare WARP image with custom APT sources
- Installs additional packages: curl, gpg, dnsutils, iputils-ping, procps
- Configures Cloudflare repository and installs cloudflare-warp package

### `entrypoint.sh`

- Critical for WARP service initialization
- Handles D-Bus setup, TUN device creation, and service registration
- Important line 28: `warp-cli --accept-tos tunnel protocol set MASQUE` (avoid
  QoS)

## Network Architecture

```
Client Apps → HTTP Proxy (58877) → WARP Container → Cloudflare Network
                                    ↓
                              Status Monitor → Log Files
```

The proxy container shares network namespace with WARP container, allowing
direct traffic routing without additional network hops.

## Development Notes

- Container requires privileged mode for TUN device and network configuration
- WARP service uses `--accept-tos` flag to automatically accept terms of service
- MASQUE protocol is mandatory due to WireGuard QoS limitations in newer
  versions
- All logs are JSON formatted and stored in `/var/log/warp/` for debugging
- Container restarts automatically on failure
- IPv6 is disabled in kernel sysctl (`net.ipv6.conf.all.disable_ipv6=0`)
