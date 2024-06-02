FROM --platform=$BUILDPLATFORM golang:latest AS build
WORKDIR /build/
COPY . /build/
ARG TARGETPLATFORM
RUN CGO_ENABLED=0 \
    GOOS=$(echo $TARGETPLATFORM | cut -d'/' -f1) \
    GOARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2) \
    go build -ldflags="-s -w" -o exec
FROM --platform=$TARGETPLATFORM debian:stable-slim
COPY --from=build /build/exec /usr/local/bin/entry
COPY entrypoint.sh /
RUN apt update && apt install curl gpg -y && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | \
    gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | \
    tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt update && \
    apt install cloudflare-warp -y && \
    apt remove -y curl && \
    apt autopurge -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["bash", "/entrypoint.sh"]