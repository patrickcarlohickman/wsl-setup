#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "MySQL"

readonly WSL_USER="${WSL_USER:-patrick}"
readonly MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"
readonly MYSQL_USER_NAME="${MYSQL_USER_NAME:-homestead}"
readonly MYSQL_USER_PASSWORD="${MYSQL_USER_PASSWORD:-secret}"
readonly WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"

# Set the root password for when mysql is installed
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-server-5.7 mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

log_info "Installing MySQL. This may take a few minutes..."

# Install mysql
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server-5.7

log_info "Setting up mysql user home directory."

# Set the home directory for the mysql user to prevent startup warnings.
usermod -d /var/lib/mysql/ mysql

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

# Run initial queries to secure the install and to create the initial user
mysql << EOF
DELETE FROM mysql.user WHERE user = '';
DELETE FROM mysql.user WHERE user = 'root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE db = 'test' OR db = 'test\\_%';
FLUSH PRIVILEGES;

CREATE USER '${MYSQL_USER_NAME}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
FLUSH PRIVILEGES;
EOF

log_info "MySQL install complete!"