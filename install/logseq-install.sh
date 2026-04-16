#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: OpenAI (Codex)
# License: MIT | https://github.com/--full/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/logseq/logseq/blob/master/docs/docker-web-app-guide.md

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

USE_DOCKER_REPO=true
setup_docker

msg_info "Configuring Logseq"
mkdir -p /opt/logseq /opt/logseq/caddy-data /opt/logseq/caddy-config

cat <<EOF >/opt/logseq/.env
LOGSEQ_IMAGE=ghcr.io/logseq/logseq-webapp:latest
LOGSEQ_HOST=${LOCAL_IP}
EOF
chmod 600 /opt/logseq/.env

cat <<EOF >/opt/logseq/Caddyfile
http://${LOCAL_IP} {
  redir https://${LOCAL_IP}{uri}
}

https://${LOCAL_IP} {
  tls internal
  reverse_proxy logseq:80
}
EOF

cat <<'EOF' >/opt/logseq/compose.yml
services:
  logseq:
    image: ${LOGSEQ_IMAGE}
    container_name: logseq
    restart: unless-stopped

  caddy:
    image: caddy:latest
    container_name: logseq-caddy
    depends_on:
      - logseq
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /opt/logseq/Caddyfile:/etc/caddy/Caddyfile:ro
      - /opt/logseq/caddy-data:/data
      - /opt/logseq/caddy-config:/config
EOF
msg_ok "Configured Logseq"

msg_info "Validating Docker Compose configuration"
cd /opt/logseq
$STD docker compose -f /opt/logseq/compose.yml config -q
msg_ok "Validated Docker Compose configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/logseq-compose.service
[Unit]
Description=Logseq Docker Compose Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/logseq
ExecStart=/usr/bin/docker compose -f /opt/logseq/compose.yml up -d
ExecStop=/usr/bin/docker compose -f /opt/logseq/compose.yml down
TimeoutStartSec=0
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now logseq-compose
msg_ok "Created Service"

echo "ghcr.io/logseq/logseq-webapp:latest" >/opt/logseq_version.txt

motd_ssh
customize
cleanup_lxc
