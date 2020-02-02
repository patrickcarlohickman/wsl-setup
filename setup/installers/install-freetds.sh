#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
#ensure_not_installed "FreeTDS"

readonly ODBC_INSTALL_FILE="${ODBC_INSTALL_FILE:-/etc/odbcinst.ini}"

log_info "Installing FreeTDS. This may take a few minutes..."

# Install freetds and dependencies.
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    unixodbc \
    unixodbc-dev \
    freetds-dev \
    freetds-bin \
    tdsodbc

log_info "Creating ODBC install file at [${ODBC_INSTALL_FILE}]."

# Create the install file and update the permissions.
cat << EOF > "${ODBC_INSTALL_FILE}"
[FreeTDS]
Driver = /usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
Setup  = /usr/lib/x86_64-linux-gnu/odbc/libtdsS.so
EOF
chmod 644 "${ODBC_INSTALL_FILE}"

log_info "FreeTDS install complete!"
