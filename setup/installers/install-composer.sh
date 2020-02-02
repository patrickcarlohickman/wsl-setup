#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "Composer"
ensure_installed "PHP"

readonly PHP="${PHP:-$(which php)}"

ensure_php_executable "${PHP}"
resolve_system_dependencies "wget"
ensure_system_dependencies "wget"

log_info "Installing Composer. This may take a few minutes..."

log_info "Downloading installer and comparing signatures."

# Get the expected composer installer hash.
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"

# Download the composer installer script.
"${PHP}" -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

# Calculate the hash of the downloaded file.
ACTUAL_SIGNATURE="$(${PHP} -r "echo hash_file('sha384', 'composer-setup.php');")"

# Make sure the expected hash and the real hash are equal.
if [ "${EXPECTED_SIGNATURE}" != "${ACTUAL_SIGNATURE}" ]; then
  log_error "Expected installer signature did not match the actual installer signature."
  rm composer-setup.php
  exit 1
fi

log_info "Running downloaded installer."

# Run the installer.
"${PHP}" composer-setup.php --quiet

log_info "Removing downloaded installer."

# Cleanup the installer.
rm composer-setup.php

log_info "Moving the composer executable into place."

# Move the executable into place.
mv composer.phar /usr/local/bin/composer

log_info "Installing common dependencies for composer functionality."

# Make sure functionality dependencies are installed.
# - zip and unzip needed for installing composer packages
resolve_system_dependencies "zip" "unzip"

log_info "Composer install complete!"
