#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_not_installed "NVM"

readonly NVM_VERSION="${NVM_VERSION:-v0.35.1}"

log_info "Installing NVM locally. This may take a few minutes..."

log_info "Downloading and running installer."

# Make sure the version is available for the install script.
wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

log_info "NVM install complete!"
