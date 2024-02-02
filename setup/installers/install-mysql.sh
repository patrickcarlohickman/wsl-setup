#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "MySQL"
ensure_variable_set "WSL_USER"

readonly WSL_USER
readonly MYSQL_AUTH_PLUGIN
readonly MYSQL_VERSION="${MYSQL_VERSION:-8.0}"
readonly MYSQL_PACKAGE="mysql-server-${MYSQL_VERSION}"
readonly MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"
readonly MYSQL_USER_NAME="${MYSQL_USER_NAME:-homestead}"
readonly MYSQL_USER_PASSWORD="${MYSQL_USER_PASSWORD:-secret}"
readonly WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"

ensure_package_available "${MYSQL_PACKAGE}"

# Set the root password for when mysql is installed
debconf-set-selections <<< "${MYSQL_PACKAGE} mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "${MYSQL_PACKAGE} mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

log_info "Installing MySQL. This may take a few minutes..."

# Install mysql
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install ${MYSQL_PACKAGE}

log_info "Setting up mysql user home directory."

# Set the home directory for the mysql user to prevent startup warnings.
usermod -d /var/lib/mysql/ mysql

# Set the default authentication plugin if specified.
if [[ -n "${MYSQL_AUTH_PLUGIN}" ]]; then
  log_info "Setting up mysql default authentication plugin."

  cat << EOF > "/etc/mysql/mysql.conf.d/auth.cnf"
[mysqld]
default_authentication_plugin=${MYSQL_AUTH_PLUGIN}
EOF
fi

log_info "Starting MySQL server."

# Make sure it is started
service mysql restart

log_info "Setting up MySQL config files."

# Create the .my.conf file with the root credentials and place it in the home
# directories for the root and the WSL users with the correct permissions.
cat << EOF > ~root/.my.cnf
[mysql]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
chmod 600 ~root/.my.cnf
cp ~root/.my.cnf "${WSL_USER_DIRECTORY}/.my.cnf"
chmod 600 "${WSL_USER_DIRECTORY}/.my.cnf"
chown "${WSL_USER}":"${WSL_USER}" "${WSL_USER_DIRECTORY}/.my.cnf"

log_info "Updating MySQL timezone information."

# Update the timezone information
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql

log_info "Securing MySQL install and initializing users."

# Identify the user with the authentication plugin if specified.
if [[ -n "${MYSQL_AUTH_PLUGIN}" ]]; then
  readonly MYSQL_USER_IDENTIFY_WITH="WITH ${MYSQL_AUTH_PLUGIN}"
else
  readonly MYSQL_USER_IDENTIFY_WITH=""
fi

# Run initial queries to secure the install and to create the initial user
mysql << EOF
DELETE FROM mysql.user WHERE user = '';
DELETE FROM mysql.user WHERE user = 'root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE db = 'test' OR db = 'test\\_%';
FLUSH PRIVILEGES;

CREATE USER '${MYSQL_USER_NAME}'@'%' IDENTIFIED ${MYSQL_USER_IDENTIFY_WITH} BY '${MYSQL_USER_PASSWORD}';
FLUSH PRIVILEGES;
EOF

log_info "MySQL install complete!"