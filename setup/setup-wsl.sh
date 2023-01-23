#!/bin/bash

set -a
source "$(dirname $(readlink -f "${0}"))/.env"
source "$(dirname $(readlink -f "${0}"))/common.sh"
set +a

ensure_root
ensure_variable_set "WSL_USER"

function main {
  local -r YN_OPTIONS=("Yes (continue)" "No (exit)")
  local SELECTED
  
  echo "Are the values in the .env file correct?"
  select SELECTED in "${YN_OPTIONS[@]}"; do
    case "${SELECTED}" in
        "${YN_OPTIONS[0]}")
          break
          ;;
        "${YN_OPTIONS[1]}")
          log_info "Please update the .env file and rerun."
          exit 1
          break
          ;;
    esac
    echo "Please choose a number from the menu above."
  done
  
  log_info "Preparing new WSL installation for use."
  prepare_installation
  
  log_info "Installing user files from setup resources."
  install_user_files
  
  log_info "Installing user SSH keys."
  install_ssh_keys
  
  log_info "Installing initial software (PHP, Composer, Apache, Ngrok, MySQL, Redis, NVM)."
  
  run_installer "install-php72.sh"
  run_installer "install-composer.sh"
  
  run_installer "install-apache.sh"
  run_installer "install-ngrok.sh"
  
  run_installer "install-mysql.sh"
  run_installer "install-redis.sh"
  
  run_installer "install-nvm-global.sh"
  
  install_freetds
}

function prepare_installation {
  debconf-set-selections <<< "* libraries/restart-without-asking boolean true"
  
  log_info "Upgrading distribution."
  upgrade_distribution
  
  log_info "Installing WSL conf file."
  install_wsl_conf
  
  log_info "Setting system timezone."
  set_timezone
  
  log_info "Installing startup script."
  install_startup_script
  
  log_info "Installing initial WSL sudoers file."
  install_wsl_sudoers
}

function upgrade_distribution {
  apt-get -yqq update
  DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
}

function install_wsl_conf {
  cp "$(script_dir)/resources/wsl/wsl.conf" "/etc/wsl.conf"
  chmod 644 "/etc/wsl.conf"
}

function set_timezone {
  "$(script_dir)/resources/wsl/set-timezone.sh"
}

function install_startup_script {
  cp "$(script_dir)/resources/wsl/startup.sh" "/usr/local/bin/startup.sh"
  chmod 755 "/usr/local/bin/startup.sh"
}

function install_wsl_sudoers {
  cp "$(script_dir)/resources/wsl/wsl-sudoers" "/etc/sudoers.d/wsl-sudoers"
  chmod 440 "/etc/sudoers.d/wsl-sudoers"
}

function install_user_files {
  local -r TEMP_DIRECTORY="$(mktemp -d -t user-XXXXXXXXXX)"
  local -r WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"
  
  [[ -z "${TEMP_DIRECTORY}" ]] && return 1
  
  cp -r "$(script_dir)/resources/bash/user" "${TEMP_DIRECTORY}"
  
  chown -R "${WSL_USER}":"${WSL_USER}" "${TEMP_DIRECTORY}"
  find "${TEMP_DIRECTORY}" -type d -exec chmod 755 {} \;
  find "${TEMP_DIRECTORY}" -type f -exec chmod 644 {} \;
  
  mv -f "${TEMP_DIRECTORY}/user/"* "${TEMP_DIRECTORY}/user/".[!.]* "${TEMP_DIRECTORY}/user/"..?* "${WSL_USER_DIRECTORY}" 2> /dev/null
  rm -rf "${TEMP_DIRECTORY}"
}

function install_ssh_keys {
  if [[ -n "$(is_ssh_key_installed)" ]]; then
    log_warning "SSH keys are already installed."
    return 1
  fi
  
  local -r WIN_USER_DIRECTORY="$(wslpath "$(windows_env_value "USERPROFILE")")"
  
  if [[ ! -f "${WIN_USER_DIRECTORY}/.ssh/id_rsa" ]]; then
    log_info "No Windows SSH keys available. Creating new SSH keys."
    
    create_new_ssh_key
    
    return 0
  fi
  
  local -r OPTIONS=("Create new SSH key" "Copy SSH keys from Windows host" "Skip")
  local -r SSH_DEFAULT_SELECT="${SSH_DEFAULT_SELECT:-0}"
  local SELECTED
  
  if [[ ${SSH_DEFAULT_SELECT} -gt 0 && ${SSH_DEFAULT_SELECT} -le ${#OPTIONS[@]} ]]; then
    local -r INDEX=$((${SSH_DEFAULT_SELECT} - 1))
    SELECTED="${OPTIONS[${INDEX}]}"
    
    case "${SELECTED}" in
        "${OPTIONS[0]}")
          log_info "Creating new SSH keys (default chosen by env)."
          
          create_new_ssh_key
          ;;
        "${OPTIONS[1]}")
          log_info "Copying Windows SSH keys (default chosen by env)."
          
          copy_windows_ssh_keys
          ;;
    esac
    
    return 0
  fi
  
  select SELECTED in "${OPTIONS[@]}"; do
    case "${SELECTED}" in
        "${OPTIONS[0]}")
          log_info "Creating new SSH keys."
          
          create_new_ssh_key
          break
          ;;
        "${OPTIONS[1]}")
          log_info "Copying Windows SSH keys."
          
          copy_windows_ssh_keys
          break
          ;;
        "${OPTIONS[2]}")
          log_info "Skipping SSH keys. No SSH keys will be available."
          
          break
          ;;
    esac
    echo "Please choose a number from the menu above, or ${#OPTIONS[@]} to exit."
  done
}

function create_new_ssh_key {
  local -r WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"
  local SSH_EMAIL_ADDRESS="${SSH_EMAIL_ADDRESS}"
  
  [[ -n "$(is_ssh_key_installed)" ]] && return 1
  
  [[ -z "${SSH_EMAIL_ADDRESS}" ]] && read -e -p "Email address for SSH key: " SSH_EMAIL_ADDRESS
  
  export WSL_USER_DIRECTORY SSH_EMAIL_ADDRESS
  su "${WSL_USER}" -c 'cat /dev/zero | ssh-keygen -t rsa -b 4096 -q -f "${WSL_USER_DIRECTORY}/.ssh/id_rsa" -N "" -C "${SSH_EMAIL_ADDRESS}" > /dev/null'
}

function copy_windows_ssh_keys {
  local -r WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"
  local -r WIN_USER_DIRECTORY="$(wslpath "$(windows_env_value "USERPROFILE")")"
  
  [[ ! -f "${WIN_USER_DIRECTORY}/.ssh/id_rsa" ]] && return 1
  
  mkdir "${WSL_USER_DIRECTORY}/.ssh"
  cp "${WIN_USER_DIRECTORY}/.ssh/id_rsa" "${WSL_USER_DIRECTORY}/.ssh/"
  cp "${WIN_USER_DIRECTORY}/.ssh/id_rsa.pub" "${WSL_USER_DIRECTORY}/.ssh/"
  chmod 700 "${WSL_USER_DIRECTORY}/.ssh"
  find "${WSL_USER_DIRECTORY}/.ssh" -type d -exec chmod 700 {} \;
  find "${WSL_USER_DIRECTORY}/.ssh" -type f -exec chmod 600 {} \;
  find "${WSL_USER_DIRECTORY}/.ssh" -type f -name "*.pub" -exec chmod 644 {} \;
  chown -R "${WSL_USER}":"${WSL_USER}" "${WSL_USER_DIRECTORY}/.ssh/"
}

function is_ssh_key_installed {
  local -r WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"
  
  [[ -f "${WSL_USER_DIRECTORY}/.ssh/id_rsa" ]] && echo "yes"
}

function install_freetds {
  run_installer "install-freetds.sh"
  
  if [[ -s "$(script_dir)/resources/freetds/odbc.ini" ]]; then
    cp "$(script_dir)/resources/freetds/odbc.ini" "/etc/odbc.ini"
    chmod 644 "/etc/odbc.ini"
  fi
  
  if [[ -s "$(script_dir)/resources/freetds/freetds.conf" ]]; then
    cp "$(script_dir)/resources/freetds/freetds.conf" "/etc/freetds/freetds.conf"
    chmod 644 "/etc/freetds/freetds.conf"
  fi
}

function run_installer {
  local -r INSTALLER="${1}"
  
  "$(script_dir)/installers/${INSTALLER}"
  
  return $?
}

main