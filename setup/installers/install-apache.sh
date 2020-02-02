#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "Apache"

readonly WSL_USER="${WSL_USER:-patrick}"

log_info "Installing Apache. This may take a few minutes..."

# Install apache
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install apache2

# Install the php apache module.
if [[ -n $(is_php_installed) ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get -y install libapache2-mod-php
fi

log_info "Enabling Apache modules."

# Enable SSL, headers, rewrite, and expires modules
a2enmod ssl
a2enmod headers
a2enmod rewrite
a2enmod expires

log_info "Enabling all available sites."

# Add this file so that all available sites are automatically enabled.
echo "Include /etc/apache2/sites-available/*.conf" > /etc/apache2/sites-enabled/vhost.conf
chmod 777 /etc/apache2/sites-enabled/vhost.conf

log_info "Enabling WSL config."

# Create the wsl.conf file and enable it.
cat << EOF > /etc/apache2/conf-available/wsl.conf
# Add these lines to prevent the "Failed to enable APR_TCP_DEFER_ACCEPT" error.
# https://github.com/Microsoft/WSL/issues/1953#issuecomment-295370994
AcceptFilter http none
AcceptFilter https none
EOF
a2enconf wsl

log_info "Updating Apache user and group."

# Change the default apache user and group to the WSL user.
sed -i "s/www-data/${WSL_USER}/g" /etc/apache2/envvars

log_info "Starting Apache."

# Make sure apache is running with the new config
service apache2 restart

log_info "Apache install complete!"
