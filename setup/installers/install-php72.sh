#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "PHP"

readonly WSL_USER="${WSL_USER:-patrick}"
readonly PHP_LOG_FILE="${PHP_LOG_FILE:-/var/log/php.log}"

# Suppress the restart libraries popup when updating libssl.
debconf-set-selections <<< "* libraries/restart-without-asking boolean true"

log_info "Installing PHP. This may take a few minutes..."

# Install php and its extensions.
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    php7.2 \
    php7.2-cgi \
    php7.2-curl \
    php7.2-enchant \
    php7.2-gmp \
    php7.2-intl \
    php7.2-mbstring \
    php7.2-opcache \
    php7.2-pspell \
    php7.2-snmp \
    php7.2-sybase \
    php7.2-xmlrpc \
    php7.2-bcmath \
    php7.2-cli \
    php7.2-dba \
    php7.2-fpm \
    php7.2-imap \
    php7.2-json \
    php7.2-mysql \
    php7.2-pgsql \
    php7.2-readline \
    php7.2-soap \
    php7.2-tidy \
    php7.2-xsl \
    php7.2-bz2 \
    php7.2-common \
    php7.2-dev \
    php7.2-gd \
    php7.2-interbase \
    php7.2-ldap \
    php7.2-odbc \
    php7.2-phpdbg \
    php7.2-recode \
    php7.2-sqlite3 \
    php7.2-xml \
    php7.2-zip

# Install the php apache module.
if [[ -n "$(is_apache_installed)" ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get -y install libapache2-mod-php
fi

log_info "Creating PHP error log file at [${PHP_LOG_FILE}]."

# Create the log file and update the permissions.
touch "${PHP_LOG_FILE}"
chown "${WSL_USER}":"${WSL_USER}" "${PHP_LOG_FILE}"
chmod 666 "${PHP_LOG_FILE}"

log_info "Enabling the PHP error log file."

# Create the error log mod file and enable it for all SAPIs.
echo "error_log = ${PHP_LOG_FILE}" > /etc/php/7.2/mods-available/error_log.ini
phpenmod -s ALL error_log

log_info "Restarting services if needed."

# Restart apache to make sure it is using the updated config.
if [[ -n "$(is_apache_installed)" ]]; then
  service apache2 restart 2> /dev/null
fi

log_info "PHP install complete!"
