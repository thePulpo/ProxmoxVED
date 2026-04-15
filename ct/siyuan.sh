#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/thePulpo/ProxmoxVED/feature/siyuan/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: OpenAI (Codex)
# License: MIT | https://github.com/--full/ProxmoxVED/raw/main/LICENSE
# Source: https://siyuannote.com/article/1725202944

APP="SiYuan"
var_tags="${var_tags:-notes;wiki;docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /opt/siyuan/compose.yml ]]; then
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
  systemctl stop siyuan-compose
  msg_ok "Stopped ${APP} stack"

  msg_info "Pulling latest ${APP} image"
  cd /opt/siyuan
  $STD docker compose pull
  msg_ok "Pulled latest ${APP} image"

  msg_info "Starting ${APP} stack"
  systemctl start siyuan-compose
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6806${CL}"
