#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "Redis"

log_info "Installing Redis. This may take a few minutes..."

# Install mysql
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install redis

log_info "Starting Redis server."

# Make sure redis is running
service redis-server restart

log_info "Redis install complete!"
