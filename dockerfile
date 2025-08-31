
from swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/ethanscully/warp:latest

copy ./debian.sources-http /etc/apt/sources.list.d/debian.sources

copy ./sources.list-http /etc/apt/sources.list


run  apt update &&  apt install apt-transport-https ca-certificates -y && apt clean && \
    rm -rf /var/lib/apt/lists/*
copy ./debian.sources /etc/apt/sources.list.d/debian.sources

copy ./sources.list /etc/apt/sources.list



RUN apt update &&  apt install -y curl gpg dbus dnsutils && \
    # RUN apt update && apt install  gpg dbus -y && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | \
    gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | \
    tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt update && \
    apt install cloudflare-warp -y  busybox sudo nano iputils-ping  procps && \
    apt install  -y  busybox sudo nano iputils-ping  procps && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh  
COPY status.sh /status.sh  
ENTRYPOINT ["bash","-x", "/entrypoint.sh","/status.sh"]