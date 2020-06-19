#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "Yarn"

log_info "Installing Yarn. This may take a few minutes..."

# Configure the repository for the yarn package.
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install yarn.
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install yarn --no-install-recommends

log_info "Yarn install complete!"
