#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "Mailpit"

readonly WSL_USER
readonly MAILPIT_DIRECTORY="${MAILPIT_DIRECTORY:-/opt/mailpit}"
readonly MAILPIT_BINARY="${MAILPIT_BINARY:-/usr/local/bin/mailpit}"
readonly MAILPIT_INSTALL_SCRIPT="${MAILPIT_INSTALL_SCRIPT:-https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh}"
readonly MAILPIT_SERVICE_NAME="mailpit"
readonly MAILPIT_SERVICE_INITD_FILE="/etc/init.d/${MAILPIT_SERVICE_NAME}"
readonly STUB_FILENAME="mailpit-stub"
readonly STUB_FILE="$(setup_resources_dir)/mailpit/init.d/${STUB_FILENAME}"
readonly STUB_SERVICE_USER_PLACEHOLDER="stub-service-user"
readonly STUB_SERVICE_NAME_PLACEHOLDER="stub-service-name"
readonly STUB_SERVICE_DIRECTORY_PLACEHOLDER="stub-service-directory"
readonly STUB_SERVICE_BINARY_PLACEHOLDER="stub-service-binary"

log_info "Installing Mailpit. This may take a few minutes..."

bash < <(curl -sL ${MAILPIT_INSTALL_SCRIPT})

log_info "Creating mailpit directory."

if [[ ! -d "${MAILPIT_DIRECTORY}" ]]; then
  mkdir -p "${MAILPIT_DIRECTORY}" -m 755
  chown ${WSL_USER}:${WSL_USER} "${MAILPIT_DIRECTORY}"
fi

log_info "Installing Mailpit service script as ${MAILPIT_SERVICE_NAME}."

# Copy the stub service file to the init.d location.
cp "${STUB_FILE}" "${MAILPIT_SERVICE_INITD_FILE}"
chmod 755 "${MAILPIT_SERVICE_INITD_FILE}"

# Replace the stub placeholders with the correct values.
sed -i "s#${STUB_SERVICE_USER_PLACEHOLDER}#${WSL_USER}#g" "${MAILPIT_SERVICE_INITD_FILE}"
sed -i "s#${STUB_SERVICE_BINARY_PLACEHOLDER}#${MAILPIT_BINARY}#g" "${MAILPIT_SERVICE_INITD_FILE}"
sed -i "s#${STUB_SERVICE_NAME_PLACEHOLDER}#${MAILPIT_SERVICE_NAME}#g" "${MAILPIT_SERVICE_INITD_FILE}"
sed -i "s#${STUB_SERVICE_DIRECTORY_PLACEHOLDER}#${MAILPIT_DIRECTORY}#g" "${MAILPIT_SERVICE_INITD_FILE}"

log_info "Starting Mailpit."

# Make sure mailpit is started
service mailpit restart

log_info "Mailpit install complete!"
