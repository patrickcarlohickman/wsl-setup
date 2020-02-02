#!/bin/bash

function main {
  readonly WD="$(dirname "$(dirname "$(script_dir)")")"

  source "${WD}/.env"
  source "${WD}/common.sh"

  if [[ -z "${COMMON_SOURCED}" || -z "${ENV_SOURCED}" ]]; then
    log_error "$(script_name) could not be initialized."
    exit 1
  fi
}

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
  local -r COLOR_OFF=${COLOR_OFF:-"\e[0m"}
  local -r COLOR_RED=${COLOR_RED:-"\e[1;91m"}
  
  log "${COLOR_RED}$@${COLOR_OFF}" "ERROR" 2
}

main
