#!/bin/bash

# Turn on the option to auto export all variables and functions created/modified.
set -a
source "$(dirname $(readlink -f "${0}"))/.env.tests"
source "$(dirname $(readlink -f "${0}"))/../setup/common.sh"
set +a

readonly PHPENV_ROOT="${PHPENV_ROOT:-/opt/phpenv}"

function main {
  log_info "Running as user: $(whoami)."

  for func in $(declare -F | grep " test_" | cut -d ' ' -f 3); do
    ${func}
  done
}

function test_0001_script_name {
  log_info "Running ${FUNCNAME[0]}..."
  
  local -r EXPECTED_SCRIPT_NAME="test.sh"
  local -r ACTUAL_SCRIPT_NAME="$(script_name)"

  if [ "${EXPECTED_SCRIPT_NAME}" != "${ACTUAL_SCRIPT_NAME}" ]; then
    log_error "script_name() returned [${ACTUAL_SCRIPT_NAME}], expected [${EXPECTED_SCRIPT_NAME}]."
    exit 1
  fi

  log_info "script_name() returned expected value [${ACTUAL_SCRIPT_NAME}]."
}

function test_0002_setup_root_dir {
  log_info "Running ${FUNCNAME[0]}..."

  local -r EXPECTED_SETUP_ROOT_DIR="$(readlink -f "$(script_dir)/../setup")"
  local -r ACTUAL_SETUP_ROOT_DIR="$(setup_root_dir)"

  if [ "${EXPECTED_SETUP_ROOT_DIR}" != "${ACTUAL_SETUP_ROOT_DIR}" ]; then
    log_error "setup_root_dir() returned [${ACTUAL_SETUP_ROOT_DIR}], expected [${EXPECTED_SETUP_ROOT_DIR}]."
    exit 1
  fi

  log_info "setup_root_dir() returned expected value [${ACTUAL_SETUP_ROOT_DIR}]."
}

function test_0003_setup_installers_dir {
  log_info "Running ${FUNCNAME[0]}..."

  local -r EXPECTED_SETUP_INSTALLERS_DIR="$(readlink -f "$(script_dir)/../setup/installers")"
  local -r ACTUAL_SETUP_INSTALLERS_DIR="$(setup_installers_dir)"

  if [ "${EXPECTED_SETUP_INSTALLERS_DIR}" != "${ACTUAL_SETUP_INSTALLERS_DIR}" ]; then
    log_error "setup_installers_dir() returned [${ACTUAL_SETUP_INSTALLERS_DIR}], expected [${EXPECTED_SETUP_INSTALLERS_DIR}]."
    exit 1
  fi

  log_info "setup_installers_dir() returned expected value [${ACTUAL_SETUP_INSTALLERS_DIR}]."
}

function test_0004_setup_resources_dir {
  log_info "Running ${FUNCNAME[0]}..."

  local -r EXPECTED_SETUP_RESOURCES_DIR="$(readlink -f "$(script_dir)/../setup/resources")"
  local -r ACTUAL_SETUP_RESOURCES_DIR="$(setup_resources_dir)"

  if [ "${EXPECTED_SETUP_RESOURCES_DIR}" != "${ACTUAL_SETUP_RESOURCES_DIR}" ]; then
    log_error "setup_resources_dir() returned [${ACTUAL_SETUP_RESOURCES_DIR}], expected [${EXPECTED_SETUP_RESOURCES_DIR}]."
    exit 1
  fi

  log_info "setup_resources_dir() returned expected value [${ACTUAL_SETUP_RESOURCES_DIR}]."
}

function test_0005_wsl_user_directory_for_root {
  log_info "Running ${FUNCNAME[0]}..."

  local -r EXPECTED_WSL_USER_DIRECTORY="/root"
  local -r ACTUAL_WSL_USER_DIRECTORY="$(wsl_user_directory "root")"

  if [ "${EXPECTED_WSL_USER_DIRECTORY}" != "${ACTUAL_WSL_USER_DIRECTORY}" ]; then
    log_error "wsl_user_directory() returned [${ACTUAL_WSL_USER_DIRECTORY}], expected [${EXPECTED_WSL_USER_DIRECTORY}]."
    exit 1
  fi

  log_info "wsl_user_directory() returned expected value [${ACTUAL_WSL_USER_DIRECTORY}]."
}

function test_0006_wsl_user_directory_for_real_user {
  log_info "Running ${FUNCNAME[0]}..."

  local -r EXPECTED_WSL_USER_DIRECTORY="/home/patrick"
  local -r ACTUAL_WSL_USER_DIRECTORY="$(wsl_user_directory "patrick")"

  if [ "${EXPECTED_WSL_USER_DIRECTORY}" != "${ACTUAL_WSL_USER_DIRECTORY}" ]; then
    log_error "wsl_user_directory() returned [${ACTUAL_WSL_USER_DIRECTORY}], expected [${EXPECTED_WSL_USER_DIRECTORY}]."
    exit 1
  fi

  log_info "wsl_user_directory() returned expected value [${ACTUAL_WSL_USER_DIRECTORY}]."
}

function test_0007_wsl_user_directory_for_missing_user {
  log_info "Running ${FUNCNAME[0]}..."

  local -r EXPECTED_WSL_USER_DIRECTORY="~missing_user"
  local -r ACTUAL_WSL_USER_DIRECTORY="$(wsl_user_directory "missing_user")"

  if [ "${EXPECTED_WSL_USER_DIRECTORY}" != "${ACTUAL_WSL_USER_DIRECTORY}" ]; then
    log_error "wsl_user_directory() returned [${ACTUAL_WSL_USER_DIRECTORY}], expected [${EXPECTED_WSL_USER_DIRECTORY}]."
    exit 1
  fi

  log_info "wsl_user_directory() returned expected value [${ACTUAL_WSL_USER_DIRECTORY}]."
}

function test_0008_strtolower {
  log_info "Running ${FUNCNAME[0]}..."

  local -r INPUT="ThIs Is A TeSt"
  local -r EXPECTED_OUTPUT="this is a test"
  local -r ACTUAL_OUTPUT="$(strtolower "${INPUT}")"

  if [ "${EXPECTED_OUTPUT}" != "${ACTUAL_OUTPUT}" ]; then
    log_error "strtolower() returned [${ACTUAL_OUTPUT}], expected [${EXPECTED_OUTPUT}]."
    exit 1
  fi

  log_info "strtolower() returned expected value [${ACTUAL_OUTPUT}]."
}

function test_0009_ensure_directory_exists_exits_when_directory_is_missing {
  log_info "Running ${FUNCNAME[0]}..."

  local -r TEST_DIR="/tmp/test-$(date +%s)-$$"

  (ensure_directory_exists "${TEST_DIR}" && exit 0) > /dev/null 2>&1

  if [ $? -ne 1 ]; then
    log_error "ensure_directory_exists() failed to ensure missing directory [${TEST_DIR}] exists."
    exit 1
  fi

  log_info "ensure_directory_exists() exited properly when directory [${TEST_DIR}] is missing."
}

function test_0010_ensure_directory_exists_returns_when_directory_exists {
  log_info "Running ${FUNCNAME[0]}..."

  local -r TEST_DIR="$(script_dir)"

  (ensure_directory_exists "${TEST_DIR}" && exit 2)

  if [ $? -ne 2 ]; then
    log_error "ensure_directory_exists() failed to return when directory [${TEST_DIR}] exists."
    exit 1
  fi

  log_info "ensure_directory_exists() returned properly when directory [${TEST_DIR}] exists."
}

function test_0011_ensure_directory_missing_exits_when_directory_exists {
  log_info "Running ${FUNCNAME[0]}..."

  local -r TEST_DIR="$(script_dir)"

  (ensure_directory_missing "${TEST_DIR}" && exit 0) > /dev/null 2>&1

  if [ $? -ne 1 ]; then
    log_error "ensure_directory_missing() failed to ensure existing directory [${TEST_DIR}] is missing."
    exit 1
  fi

  log_info "ensure_directory_missing() exited properly when directory [${TEST_DIR}] exists."
}

function test_0012_ensure_directory_missing_returns_when_directory_is_missing {
  log_info "Running ${FUNCNAME[0]}..."

  local -r TEST_DIR="/tmp/test-$(date +%s)-$$"

  (ensure_directory_missing "${TEST_DIR}" && exit 2)

  if [ $? -ne 2 ]; then
    log_error "ensure_directory_missing() failed to return when directory [${TEST_DIR}] is missing."
    exit 1
  fi

  log_info "ensure_directory_missing() returned properly when directory [${TEST_DIR}] is missing."
}

main
