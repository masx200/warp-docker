FROM golang:latest AS build
WORKDIR /build/
COPY . /build/
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o exec
FROM debian:stable-slim
COPY --from=build /build/exec /usr/local/bin/entry

RUN apt update && apt install curl gpg -y
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | tee /etc/apt/sources.list.d/cloudflare-client.list
RUN apt update && \
    apt install cloudflare-warp -y && \
    apt remove -y curl && \
    apt autopurge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /root/
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]