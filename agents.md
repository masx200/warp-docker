# agents.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

这是一个基于 Docker 的 Cloudflare WARP 客户端实现，提供安全的 zero trust 连接和
HTTP 代理服务。项目通过 Docker Compose 集成两个主要服务：

1. **HTTP 代理服务器** - 基于 Go 的 HTTP/HTTPS 代理，集成 DoH（DNS over HTTPS）
2. **WARP Docker 容器** - 运行 MASQUE 协议的 Cloudflare WARP 客户端，避免
   WireGuard QoS 限制

## 常用开发命令

### Docker 操作

- **构建 Docker 镜像**:
  `docker build -f dockerfile -t "docker.cnb.cool/masx200/docker_mirror/warp-docker:latest" .`
- **使用脚本构建**: `./build.sh` (需要执行权限)
- **启动服务**: `docker-compose up -d`
- **停止服务**: `docker-compose down`
- **查看所有日志**: `docker-compose logs -f`
- **查看特定服务日志**: `docker-compose logs -f warp-docker` 或
  `docker-compose logs -f http-proxy-go-server`
- **监控 WARP 状态**: 查看运行中的容器日志或进入容器执行
  `warp-cli --accept-tos --json --verbose status`

### 开发环境设置

- **设置 TUN 设备**: 容器自动创建 `/dev/net/tun`，但主机可能需要手动创建:
  `mkdir -p /dev/net && mknod /dev/net/tun c 10 200 && chmod 600 /dev/net/tun`
- **网络配置**: 使用外部 `dpanel-network`，配置 IPv4 (`172.31.123.0/24`) 和 IPv6
  (`fd12:5687:4425:5555::/64`) 的 IPAM

## 架构概览

### 服务组件

**HTTP 代理服务器 (`http-proxy-go-server`)**:

- 端口: 58877 (HTTP/HTTPS 代理)
- 凭据: admin (用户)，通过 `${password}` 环境变量配置密码
- DoH 服务器: 自定义服务器 + Cloudflare 的 1.1.1.1，支持 h2/h3
- 镜像: `docker.cnb.cool/masx200/docker_mirror/http-proxy-go-server:2.6.0`
- 使用 Go 1.24.4 构建，支持 HTTP/2 和 HTTP/3

**WARP 容器 (`warp-docker`)**:

- 基础镜像: 修改后的 Cloudflare WARP 容器，带有自定义 APT 源
- 关键能力: `NET_ADMIN`, `MKNOD`, `AUDIT_WRITE`
- 设备: `/dev/net/tun` 用于 VPN 隧道
- 协议: MASQUE（自动配置以避免 WireGuard QoS）
- 模式: `warp+doh` 带自动注册
- 日志存储在 `/var/log/warp/` 目录

**Curl 监控器 (`curl-monitor`)**:

- 每 60 秒自动进行连通性测试
- 使用 HTTP/2 通过 Google 测试代理功能
- 以特权用户身份运行进行网络测试

### 入口点流程 (`entrypoint.sh`)

1. 如果缺少 TUN 设备则创建
2. 启动 D-Bus 服务（WARP 需要）
3. 初始化日志目录
4. 在后台启动 WARP 服务
5. 等待 WARP 服务就绪（注册循环）
6. 设置协议为 MASQUE（避免 WireGuard QoS）
7. 注册新的 WARP 设备（先删除旧注册）
8. 连接到 WARP 网络
9. 等待 Cloudflare 连通性验证
10. 将控制权转移给命令或启动状态监控器

## 关键配置文件

### `docker-compose.yml`

- 使用外部 `dpanel-network` 带自定义 IPAM
- 三个服务：代理、WARP 客户端和监控
- 环境变量 `${password}` 用于代理认证
- 日志配置，最大 100MB，5 个文件轮转

### `dockerfile`

- 基于 Cloudflare WARP 镜像，带有自定义 APT 源
- 安装额外包：curl, gpg, dnsutils, iputils-ping, procps
- 配置 Cloudflare 仓库并安装 cloudflare-warp 包

### `entrypoint.sh`

- WARP 服务初始化的关键文件
- 处理 D-Bus 设置、TUN 设备创建和服务注册
- 重要第 28 行：`warp-cli --accept-tos tunnel protocol set MASQUE`（避免 QoS）

## 网络架构

```
客户端应用 → HTTP 代理 (58877) → WARP 容器 → Cloudflare 网络
                                    ↓
                              状态监控器 → 日志文件
```

代理容器与 WARP 容器共享网络命名空间，允许直接流量路由而无需额外的网络跳数。

## 开发注意事项

- 容器需要特权模式来配置 TUN 设备和网络
- WARP 服务使用 `--accept-tos` 标志来自动接受服务条款
- MASQUE 协议是必需的，因为新版本中 WireGuard 存在 QoS 限制
- 所有日志都是 JSON 格式并存储在 `/var/log/warp/` 中用于调试
- 容器在故障时自动重启
- IPv6 在内核 sysctl 中被禁用 (`net.ipv6.conf.all.disable_ipv6=0`)
