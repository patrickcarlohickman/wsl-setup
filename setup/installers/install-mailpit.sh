#!/bin/bash

# 1. Install mailpit
# 2. Create mailpit directory with correct owner and permissions
# 3. Install mailpit service script as mailpit
#    - @todo: convert to stub file and implement stub replacements
# 4. Start mailpit service

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "Mailpit"

readonly WSL_USER
readonly MAILPIT_DIRECTORY="${MAILPIT_DIRECTORY:-/opt/mailpit}"
readonly MAILPIT_SERVICE_NAME="mailpit"
readonly MAILPIT_SERVICE_RESOURCE_FILE="$(script_dir)/resources/mailpit/init.d/mailpit"
readonly MAILPIT_SERVICE_INITD_FILE="/etc/init.d/${MAILPIT_SERVICE_NAME}"

log_info "Installing Mailpit. This may take a few minutes..."

bash < <(curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh)

log_info "Creating mailpit directory."

if [[ ! -d "${MAILPIT_DIRECTORY}" ]]; then
  mkdir -p "${MAILPIT_DIRECTORY}"
  chown ${WSL_USER}:${WSL_USER} "${MAILPIT_DIRECTORY}"
  chmod 755 "${MAILPIT_DIRECTORY}"
fi

log_info "Installing Mailpit service script as ${MAILPIT_SERVICE_NAME}."

cp "${MAILPIT_SERVICE_RESOURCE_FILE}" "${MAILPIT_SERVICE_INITD_FILE}"
chmod 755 "${MAILPIT_SERVICE_INITD_FILE}"

log_info "Starting Mailpit."

# Make sure mailpit is started
service mailpit restart

log_info "Mailpit install complete!"
