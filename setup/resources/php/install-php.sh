#!/bin/bash

source "$(dirname "$(dirname "$(readlink -f "${0}")")")/init-resource.sh"

function usage {
  echo "Usage: $(script_name) < php_version | latest >"
}

PHP_VERSION="${1}"

if [[ $# -lt 1 || "${PHP_VERSION}" = "-h" || "${PHP_VERSION}" = "--help" ]]; then
  usage
  exit 1
fi

ensure_root
ensure_installed "PHPENV" "PHPENV is required but is not found at ${PHPENV_ROOT} or is not loaded. If using sudo, make sure to use a login shell (sudo -i)."

log_info "Installing PHP version ${PHP_VERSION}."

if [[ "${PHP_VERSION}" == "latest" ]]; then
  PHP_VERSION="$(phpenv_latest_version)"

  log_info "Latest PHP version resolved to ${PHP_VERSION}."
fi

run_installer "install-php.sh" "${PHP_VERSION}"

log_info "PHP version ${PHP_VERSION} is now available."
