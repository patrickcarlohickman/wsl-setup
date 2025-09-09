#!/bin/bash

[[ -n "${COMMON_SOURCED}" ]] && return
declare -xr COMMON_SOURCED="yes"

readonly COLOR_OFF=${COLOR_OFF:-"\e[0m"}
readonly COLOR_RED=${COLOR_RED:-"\e[1;91m"}
readonly COLOR_GREEN=${COLOR_GREEN:-"\e[1;92m"}
readonly COLOR_YELLOW=${COLOR_YELLOW:-"\e[1;93m"}

readonly SETUP_ROOT_DIR="$(dirname $(readlink -f "${BASH_SOURCE}"))"
readonly SETUP_INSTALLERS_DIR="${SETUP_ROOT_DIR}/installers"
readonly SETUP_RESOURCES_DIR="${SETUP_ROOT_DIR}/resources"

function script_name {
  echo "$(basename "${0}")"
}

function script_dir {
  echo "$(dirname $(readlink -f "${0}"))"
}

function now {
  echo "$(date '+%F %T')"
}

function log {
  local -r MSG="${1}"
  local -r LEVEL="${2:-INFO}"
  local -r FD=${3:-1}

  echo -e "[$(now)] [$(script_name)] [${LEVEL}] : ${MSG}" >&${FD}
}

function log_error {
  log "${COLOR_RED}$@${COLOR_OFF}" "ERROR" 2
}

function log_warning {
  log "${COLOR_YELLOW}$@${COLOR_OFF}" "WARN"
}

function log_info {
  log "${COLOR_GREEN}$@${COLOR_OFF}" "INFO"
}

function log_debug {
  log "$@" "DEBUG"
}

function setup_root_dir {
  echo "${SETUP_ROOT_DIR}"
}

function setup_installers_dir {
  echo "${SETUP_INSTALLERS_DIR}"
}

function setup_resources_dir {
  echo "${SETUP_RESOURCES_DIR}"
}

function wsl_user_directory {
  local -r WHO="${1:-${WSL_USER}}"

  echo "$(eval echo $(printf "~%q" "${WHO}"))"
}

function ensure_root {
  local -r EXIT_CODE=${1:-1}

  if [[ $(id -u) -ne 0 ]]; then
    log_error "$(script_name) must be run as root."
    exit ${EXIT_CODE}
  fi
}

function ensure_user {
  local -r WHO="${1}"
  local -r EXIT_CODE=${2:-1}

  if [[ $(whoami) != "${WHO}" ]]; then
    log_error "$(script_name) must be run as ${WHO}."
    exit ${EXIT_CODE}
  fi
}

function strtolower {
  echo "$@" | tr '[:upper:]' '[:lower:]'
}

function resolve_system_dependencies {
  local missing=()
  local dep

  for dep in "$@"; do
    [[ -z "$(dpkg -l | egrep "ii\s*${dep}(:|\s+)" )" ]] && missing+=("${dep}")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_info "Installing missing system dependencies [${missing[*]}]. This may take a few minutes..."
    apt-get -yqq update
    DEBIAN_FRONTEND=noninteractive apt-get -y install ${missing[@]}
    log_info "Installing missing system dependencies complete."
  fi
}

function ensure_system_dependencies {
  local missing=()
  local dep

  for dep in "$@"; do
    [[ -z "$(dpkg -l | egrep "ii\s*${dep}(:|\s+)" )" ]] && missing+=("${dep}")
  done

  if [[ ${#missing[@]} -gt 1 ]]; then
    log_error "System dependencies [${missing[*]}] are missing."
    exit 1
  elif [[ ${#missing[@]} -eq 1 ]]; then
    log_error "System dependency [${missing[*]}] is missing."
    exit 1
  fi
}

function ensure_directory_exists {
  if [[ ! -d "${1}" ]]; then
    log_error "Directory ${1} does not exist."
    exit 1
  fi
}

function ensure_directory_missing {
  if [[ -d "${1}" ]]; then
    log_error "Directory ${1} already exists."
    exit 1
  fi
}

function ensure_installed {
  local -r APP="${1%%-*}"
  local -r PARAM_LIST="${1#*-}"
  local -r PARAMS=(${PARAM_LIST//-/ })
  local -r APP_LOWER="$(strtolower "${APP}")"
  local -r MESSAGE="${2:-"${APP} is required but is not installed."}"

  if [[ -z "$("is_${APP_LOWER}_installed" ${PARAMS[@]})" ]]; then
    log_error "${MESSAGE}"
    exit 1
  fi
}

function ensure_not_installed {
  local -r APP="${1%%-*}"
  local -r PARAM_LIST="${1#*-}"
  local -r PARAMS=(${PARAM_LIST//-/ })
  local -r APP_LOWER="$(strtolower "${APP}")"
  local -r MESSAGE="${2:-"${APP} is already installed."}"

  if [[ -n "$("is_${APP_LOWER}_installed" ${PARAMS[@]})" ]]; then
    log_error "${MESSAGE}"
    exit 1
  fi
}

function ensure_variable_set {
  if [[ -z "${!1}" ]]; then
    log_error "Variable ${1} is required but is either not set or is empty."
    exit 1
  fi
}

function ensure_package_available {
  if [[ -z "$(apt-cache search --names-only "^${1}")" ]]; then
    log_error "Package ${1} was not found as an installable package."
    exit 1
  fi
}

function is_mysql_installed {
  dpkg -l | egrep "ii\s*mysql-server\S*\s+" > /dev/null

  [[ $? -eq 0 ]] && echo "yes"
}

function is_redis_installed {
  dpkg -l | egrep "ii\s*redis-server\S*\s+" > /dev/null

  [[ $? -eq 0 ]] && echo "yes"
}

function is_apache_installed {
  dpkg -l | egrep "ii\s*apache2\s+" > /dev/null

  [[ $? -eq 0 ]] && echo "yes"
}

function is_php_installed {
  [[ -n "$(which php)" ]] && echo "yes"
}

function is_ngrok_installed {
  [[ -n "$(which ngrok)" ]] && echo "yes"
}

function is_composer_installed {
  [[ -n "$(which composer)" ]] && echo "yes"
}

function is_nvm_installed {
  [[ -s "${NVM_DIR}/nvm.sh" ]] && echo "yes"
}

function is_node_installed {
  local -r VERSION="${1}"

  [[ -n "$(is_nvm_installed)" ]] && source "${NVM_DIR}/nvm.sh" > /dev/null

  nvm ls "${VERSION}" > /dev/null

  [[ $? -eq 0 ]] && echo "yes"
}

function is_freetds_installed {
  dpkg -l | egrep "ii\s*freetds-bin\s+" > /dev/null

  [[ $? -eq 0 ]] && echo "yes"
}

function is_yarn_installed {
  [[ -n "$(which yarn)" ]] && echo "yes"
}

function is_phpenv_installed {
  local -r LOCAL_PHPENV_ROOT="${PHPENV_ROOT:-/opt/phpenv}"

  [[ -s "${LOCAL_PHPENV_ROOT}/bin/phpenv" ]] && [[ -n "$(which phpenv)" ]] && echo "yes"
}

function is_phpenv_version_installed {
  local -r VERSION="${1}"

  [[ -n "$(is_phpenv_installed)" ]] && phpenv versions | egrep -q "(^|\s+)${VERSION}(\s+|$)"

  [[ $? -eq 0 ]] && echo "yes"
}

function phpenv_latest_version {
  [[ -n "$(is_phpenv_installed)" ]] && echo "$(phpenv install -l | grep -v snapshot | tail -n 1 | tr -d "[:space:]")"
}

function ensure_php_executable {
  local php="$@"

  if [[ -z "${php}" ]]; then
    log_error "PHP executable was not found."
    exit 1
  fi

  if [[ ! -x "${php}" ]]; then
    log_error "PHP command [${php}] is not a file or not executable."
    exit 1
  fi

  ${php} -v | grep -i "php" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    log_error "PHP command [${php}] does not appear to execute PHP."
  fi
}

function ensure_file_exists {
  local -r FILE="${1}"

  if [[ ! -f "${FILE}" ]]; then
    log_error "File ${FILE} is required but is not found."
    exit 1
  fi
}

function ensure_file_missing {
  local -r FILE="${1}"

  if [[ -f "${FILE}" ]]; then
    log_error "File ${FILE} already exists."
    exit 1
  fi
}

function windows_mount {
  local windir
  local drive

  # Assign on separate line in order to capture exit code.
  windir="$(which explorer.exe)"

  # First try to get Windows directory from which command.
  if [[ $? -eq 0 ]] && [[ -n "${windir}" ]]; then
    windir="$(dirname "$(dirname "${windir}")")"

    if [[ -d "${windir}" ]]; then
      echo "${windir}"
      return 0
    fi
  fi

  # If Windows is not in path, fallback to /mnt loop.
  for drive in /mnt/*; do
    if [[ -x "${drive}/Windows/explorer.exe" ]]; then
      echo "${drive}"
      return 0
    fi
  done

  return 1
}

function windows_cmd_exe {
  local -r CMD_EXE="$(windows_mount)/Windows/System32/cmd.exe"

  if [[ -x "${CMD_EXE}" ]]; then
    echo "${CMD_EXE}"
    return 0
  fi

  return 1
}

function windows_cmd {
  local -r CMD="${1}"
  local -r CMD_EXE="$(windows_cmd_exe)"

  if [[ -z "${CMD_EXE}" ]]; then
    return 1
  fi

  local -r CMD_DIR="$(dirname "${CMD_EXE}")"

  if [[ -d "${CMD_DIR}" ]]; then
    echo "$(pushd ${CMD_DIR} > /dev/null; ./cmd.exe /C "${CMD}"; popd > /dev/null)"
  fi
}

function windows_env_value {
  local -r VAR="${1}"
  local -r VALUE="$(windows_cmd "if defined ${VAR} (echo %${VAR}%) else (echo.)")"

  echo "${VALUE//$'\r'}"
}

function version_compare {
  dpkg --compare-versions "${1}" "${2}" "${3}"

  return $?
}

function run_installer {
  local -r INSTALLER="${1}"

  shift

  "$(setup_installers_dir)/${INSTALLER}" "$@"

  return $?
}
