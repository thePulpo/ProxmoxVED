#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/thePulpo/ProxmoxVED/feature/logseq/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: OpenAI (Codex)
# License: MIT | https://github.com/--full/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/logseq/logseq/blob/master/docs/docker-web-app-guide.md

APP="Logseq"
var_tags="${var_tags:-notes;wiki;docker}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_nesting="${var_nesting:-1}"
var_keyctl="${var_keyctl:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/logseq/compose.yml ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating base system"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Base system updated"

  msg_info "Updating Docker Engine"
  $STD apt install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
  msg_ok "Docker Engine updated"

  msg_info "Stopping ${APP} stack"
  systemctl stop logseq-compose
  msg_ok "Stopped ${APP} stack"

  msg_info "Pulling latest ${APP} images"
  cd /opt/logseq
  $STD docker compose pull
  msg_ok "Pulled latest ${APP} images"

  msg_info "Starting ${APP} stack"
  systemctl start logseq-compose
  msg_ok "Started ${APP} stack"

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
echo -e "${INFO}${YW} Trust the generated Caddy root certificate before remote access:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}/opt/logseq/caddy-data/caddy/pki/authorities/local/root.crt${CL}"
