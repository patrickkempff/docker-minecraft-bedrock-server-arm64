FROM debian

# ARCH is only set to avoid repetition in Dockerfile since the binary download only supports amd64
ARG ARCH=arm64

ARG APT_UPDATE=20210112

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    unzip \
    jq \
    debian-keyring \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    
RUN wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list && \
    wget -O- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor | tee /usr/share/keyrings/box64-debs-archive-keyring.gpg && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y box64

EXPOSE 19132/udp

VOLUME ["/data"]

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint-demoter", "--match", "/data", "--debug", "--stdin-on-term", "stop", "/opt/bedrock-entry.sh"]

ARG EASY_ADD_VERSION=0.7.0
ADD https://github.com/itzg/easy-add/releases/download/${EASY_ADD_VERSION}/easy-add_linux_${ARCH} /usr/local/bin/easy-add
RUN chmod +x /usr/local/bin/easy-add

RUN easy-add --var version=0.4.0 --var app=entrypoint-demoter --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/v{{.version}}/{{.app}}_{{.version}}_linux_${ARCH}.tar.gz

RUN easy-add --var version=0.1.1 --var app=set-property --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_linux_${ARCH}.tar.gz

RUN easy-add --var version=1.5.0 --var app=restify --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/v{{.version}}/{{.app}}_{{.version}}_linux_${ARCH}.tar.gz

RUN easy-add --var version=0.5.0 --var app=mc-monitor --file {{.app}} --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_linux_${ARCH}.tar.gz

COPY *.sh /opt/

COPY property-definitions.json /etc/bds-property-definitions.json

# Available versions listed at
# https://minecraft.gamepedia.com/Bedrock_Edition_1.11.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.12.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.13.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.14.0
ENV VERSION=LATEST \
    SERVER_PORT=19132

HEALTHCHECK --start-period=1m CMD /usr/local/bin/mc-monitor status-bedrock --host 127.0.0.1 --port $SERVER_PORT
