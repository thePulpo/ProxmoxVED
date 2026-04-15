#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: OpenAI (Codex)
# License: MIT | https://github.com/--full/ProxmoxVED/raw/main/LICENSE
# Source: https://siyuannote.com/article/1725202944

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

function random_alnum() {
  local length="${1:-20}"
  local value=""

  while [[ "${#value}" -lt "${length}" ]]; do
    value="${value}$(tr -d '-' </proc/sys/kernel/random/uuid)"
  done

  printf '%s' "${value:0:${length}}"
}

USE_DOCKER_REPO=true
setup_docker

msg_info "Configuring SiYuan"
AUTH_CODE="$(random_alnum 24)"
TIME_ZONE_VALUE="$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo UTC)"

mkdir -p /opt/siyuan /opt/siyuan/workspace
chown -R 1000:1000 /opt/siyuan/workspace

cat <<EOF >/opt/siyuan/.env
TZ=${TIME_ZONE_VALUE}
PUID=1000
PGID=1000
SIYUAN_IMAGE=b3log/siyuan:latest
SIYUAN_AUTH_CODE=${AUTH_CODE}
EOF
chmod 600 /opt/siyuan/.env

cat <<'EOF' >/opt/siyuan/compose.yml
services:
  main:
    image: ${SIYUAN_IMAGE}
    container_name: siyuan
    command:
      - --workspace=/siyuan/workspace/
      - --accessAuthCode=${SIYUAN_AUTH_CODE}
    ports:
      - "6806:6806"
    volumes:
      - /opt/siyuan/workspace:/siyuan/workspace
    restart: unless-stopped
    environment:
      TZ: ${TZ}
      PUID: ${PUID}
      PGID: ${PGID}
EOF
msg_ok "Configured SiYuan"

msg_info "Validating Docker Compose configuration"
cd /opt/siyuan
$STD docker compose -f /opt/siyuan/compose.yml config -q
msg_ok "Validated Docker Compose configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/siyuan-compose.service
[Unit]
Description=SiYuan Docker Compose Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/siyuan
ExecStart=/usr/bin/docker compose -f /opt/siyuan/compose.yml up -d
ExecStop=/usr/bin/docker compose -f /opt/siyuan/compose.yml down
TimeoutStartSec=0
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now siyuan-compose
msg_ok "Created Service"

echo "b3log/siyuan:latest" >/opt/siyuan_version.txt

motd_ssh
customize
cleanup_lxc
