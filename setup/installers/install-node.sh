#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_variable_set "WSL_USER"

readonly WSL_USER
readonly NVM_DIR="${NVM_DIR:-${NVM_DIR_GLOBAL:-/opt/nvm}}"
readonly INSTALL_NODE_VERSION="${INSTALL_NODE_VERSION:-v10.11.0}"
readonly COMMON="$(dirname "$(dirname "$(readlink -f "${0}")")")/common.sh"

log_info "Installing Node ${INSTALL_NODE_VERSION} as ${WSL_USER}. This may take a few minutes..."

sudo -i -u "${WSL_USER}" bash <<EOF
source "${COMMON}"

NVM_DIR="\${HOME}/.nvm"
[[ -z "\$(is_nvm_installed)" ]] && NVM_DIR="${NVM_DIR}"

ensure_user "${WSL_USER}"
ensure_installed "NVM" "NVM is required but is not loaded and is not found at \${NVM_DIR}."
ensure_not_installed "node-${INSTALL_NODE_VERSION}"

log_info "Sourcing NVM."

# Load NVM for the script to use.
source "\${NVM_DIR}/nvm.sh"

log_info "Installing Node ${INSTALL_NODE_VERSION} using NVM in \${NVM_DIR}."

# Install node using NVM.
nvm install "${INSTALL_NODE_VERSION}"
EOF

# Exit if the install commands failed.
[[ $? -ne 0 ]] && exit 1

log_info "Installing common dependencies for node functionality."

# Make sure functionality dependencies are installed.
# - libpng-dev needed for node packages
resolve_system_dependencies "libpng-dev"

log_warning "Node and NPM were installed via NVM. Reload your shell to use them."

log_info "Node ${INSTALL_NODE_VERSION} install complete!"
