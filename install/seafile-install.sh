#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: OpenAI (Codex)
# License: MIT | https://github.com/--full/ProxmoxVED/raw/main/LICENSE
# Source: https://manual.seafile.com/latest/setup/setup_ce_by_docker/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

function random_alnum() {
  local length="${1:-20}"
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${length}"
}

function set_env_value() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" /opt/seafile/.env; then
    sed -i "s|^${key}=.*|${key}=${value}|" /opt/seafile/.env
  else
    echo "${key}=${value}" >>/opt/seafile/.env
  fi
}

USE_DOCKER_REPO=true
setup_docker

msg_info "Downloading Seafile Docker files"
mkdir -p /opt/seafile /opt/seafile-data /opt/seafile-mysql/db /opt/seafile-caddy
curl_with_retry "https://manual.seafile.com/13.0/repo/docker/ce/env" "/opt/seafile/.env"
curl_with_retry "https://manual.seafile.com/13.0/repo/docker/ce/seafile-server.yml" "/opt/seafile/seafile-server.yml"
curl_with_retry "https://manual.seafile.com/13.0/repo/docker/seadoc.yml" "/opt/seafile/seadoc.yml"
curl_with_retry "https://manual.seafile.com/13.0/repo/docker/caddy.yml" "/opt/seafile/caddy.yml"
msg_ok "Downloaded Seafile Docker files"

msg_info "Configuring Seafile"
MYSQL_ROOT_PASSWORD="$(random_alnum 24)"
SEAFILE_DB_PASSWORD="$(random_alnum 24)"
SEAFILE_ADMIN_PASSWORD="$(random_alnum 20)"
JWT_PRIVATE_KEY="$(random_alnum 40)"
TIME_ZONE_VALUE="$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo UTC)"

set_env_value "SEAFILE_VOLUME" "/opt/seafile-data"
set_env_value "SEAFILE_MYSQL_VOLUME" "/opt/seafile-mysql/db"
set_env_value "SEAFILE_CADDY_VOLUME" "/opt/seafile-caddy"
set_env_value "INIT_SEAFILE_MYSQL_ROOT_PASSWORD" "${MYSQL_ROOT_PASSWORD}"
set_env_value "SEAFILE_MYSQL_DB_PASSWORD" "${SEAFILE_DB_PASSWORD}"
set_env_value "JWT_PRIVATE_KEY" "${JWT_PRIVATE_KEY}"
set_env_value "SEAFILE_SERVER_HOSTNAME" "${LOCAL_IP}"
set_env_value "SEAFILE_SERVER_PROTOCOL" "http"
set_env_value "CACHE_PROVIDER" "redis"
set_env_value "TIME_ZONE" "${TIME_ZONE_VALUE}"
set_env_value "INIT_SEAFILE_ADMIN_EMAIL" "admin@seafile.local"
set_env_value "INIT_SEAFILE_ADMIN_PASSWORD" "${SEAFILE_ADMIN_PASSWORD}"
chmod 600 /opt/seafile/.env
msg_ok "Configured Seafile"

msg_info "Validating Docker Compose configuration"
cd /opt/seafile
$STD docker compose config -q
msg_ok "Validated Docker Compose configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/seafile-compose.service
[Unit]
Description=Seafile Docker Compose Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/seafile
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seafile-compose
msg_ok "Created Service"

echo "13.0-latest" >/opt/seafile_version.txt

motd_ssh
customize
cleanup_lxc
