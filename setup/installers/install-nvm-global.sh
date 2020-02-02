#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root

readonly NVM_VERSION="${NVM_VERSION:-v0.35.1}"
NVM_DIR="${NVM_DIR:-${NVM_DIR_GLOBAL:-/opt/nvm}}"
NVM_PROFILE="${NVM_PROFILE:-/etc/bash.bashrc}"
readonly NVM_PROFILE_ORIG="${NVM_PROFILE}"

ensure_not_installed "NVM"

log_info "Installing NVM globally. This may take a few minutes..."

log_info "Creating NVM directory."

# Make sure the NVM install dir exists with global permissions.
if [[ ! -d "${NVM_DIR}" ]]; then
  mkdir -p -m 777 "${NVM_DIR}"
fi

log_info "Faking NVM profile."

# Make sure the NVM_PROFILE file is a .bashrc file. NVM checks this to
# to determine whether or not to add in bash completion.
if [[ "${NVM_PROFILE##*/}" != ".bashrc" ]]; then
  NVM_PROFILE="/tmp/.bashrc"
  rm "${NVM_PROFILE}"
fi

# Make sure the profile file exists.
touch "${NVM_PROFILE}"

log_info "Downloading and running installer."

# Install NVM with the proper NVM_DIR and PROFILE variables.
wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | NVM_DIR="${NVM_DIR}" PROFILE="${NVM_PROFILE}" bash

log_info "Updating NVM profile."

# If the NVM_PROFILE variable was temporarily changed, update the real profile
# file with the updates made by NVM, and then remove the temporary file.
if [[ "${NVM_PROFILE}" != "${NVM_PROFILE_ORIG}" ]]; then
  cat "${NVM_PROFILE}" >> "${NVM_PROFILE_ORIG}"
  rm "${NVM_PROFILE}"
fi

log_info "NVM install complete!"
