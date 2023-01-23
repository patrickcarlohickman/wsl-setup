#!/bin/bash

source "$(dirname "$(dirname "$(readlink -f "${0}")")")/init-resource.sh"

function usage {
  echo "Usage: $(script_name) < domain > < php_version > [ directory [ ngrok_start_name ] ]"
}

readonly NEW_SITE_DOMAIN="${1}"
readonly PHP_VERSION="${2}"
readonly NEW_SITE_DIRECTORY="${3:-${1}/public}"
readonly NGROK_START_NAME="${4:-${1}}"

readonly VHOST_DIRECTORY="${VHOST_DIRECTORY:-/var/www/vhost}"
readonly SITES_DIRECTORY="/etc/apache2/sites-available"
readonly STUB_FILENAME="apache-site-stub.conf"
readonly STUB_DOMAIN_PLACEHOLDER="stub-domain"
readonly STUB_VHOST_DIRECTORY_PLACEHOLDER="stub-vhost"
readonly STUB_DIRECTORY_PLACEHOLDER="stub-folder"
readonly STUB_CERT_KEY_PLACEHOLDER="stub-cert-key"
readonly STUB_CERT_FILE_PLACEHOLDER="stub-cert-file"
readonly STUB_PHP_VERSION_PLACEHOLDER="stub-php-version"
readonly NGROK_DIRECTORY="${NGROK_DIRECTORY:-/opt/ngrok}"
readonly NGROK_CONFIG="${NGROK_DIRECTORY}/conf/ngrok.yml"
readonly SSL_CERT_NAME="${SSL_CERT_NAME:-ssl-self-signed-local-dev}"
readonly STUB_FILE="$(script_dir)/${STUB_FILENAME}"
readonly NEW_SITE_CONFIG="${SITES_DIRECTORY}/${NEW_SITE_DOMAIN}.conf"
readonly SSL_KEY_DIRECTORY="${SSL_KEY_DIRECTORY:-/etc/ssl/private}"
readonly SSL_CERT_DIRECTORY="${SSL_CERT_DIRECTORY:-/etc/ssl/certs}"
readonly SSL_KEY_FILE="${SSL_KEY_DIRECTORY}/${SSL_CERT_NAME}.key"
readonly SSL_CERT_FILE="${SSL_CERT_DIRECTORY}/${SSL_CERT_NAME}.pem"
readonly SSL_DEFAULT_CONF_FILE="$(script_dir)/openssl.default.cnf"
readonly SSL_WORKING_CONF_FILE="$(script_dir)/openssl.cnf"

if [[ $# -lt 1 || "${NEW_SITE_DOMAIN}" = "-h" || "${NEW_SITE_DOMAIN}" = "--help" ]]; then
  usage
  exit 1
fi

ensure_root
ensure_installed "Apache"
ensure_installed "PHPENV" "PHPENV is required but is not found at ${PHPENV_ROOT} or is not loaded. If using sudo, make sure to use a login shell (sudo -i)."
ensure_installed "phpenv_version-${PHP_VERSION}" "PHP version [${PHP_VERSION}] is required but is not installed."
ensure_file_exists "${STUB_FILE}"
ensure_file_exists "${SSL_DEFAULT_CONF_FILE}"
ensure_file_missing "${NEW_SITE_CONFIG}"

log_info "Setting up new site config file."

# Copy the stub template file to the new site config file.
cp "${STUB_FILE}" "${NEW_SITE_CONFIG}"

# Replace the stub placeholders with the new site values.
sed -i "s#${STUB_DOMAIN_PLACEHOLDER}#${NEW_SITE_DOMAIN}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_VHOST_DIRECTORY_PLACEHOLDER}#${VHOST_DIRECTORY}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_DIRECTORY_PLACEHOLDER}#${NEW_SITE_DIRECTORY}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_CERT_KEY_PLACEHOLDER}#${SSL_KEY_FILE}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_CERT_FILE_PLACEHOLDER}#${SSL_CERT_FILE}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_PHP_VERSION_PLACEHOLDER}#${PHP_VERSION}#g" "${NEW_SITE_CONFIG}"

# Make sure the DocumentRoot directory of the new site actually exists.
if [[ "$(grep -m 1 "DocumentRoot" "${NEW_SITE_CONFIG}")" =~ DocumentRoot[[:blank:]]+(.+) ]]; then
  readonly DOCUMENT_ROOT="${BASH_REMATCH[1]}"
  
  if [[ ! -d "${DOCUMENT_ROOT}" ]]; then
    log_error "Configured document root ${DOCUMENT_ROOT} does not exist."
    log_error "Removing site config ${NEW_SITE_CONFIG}"
    
    rm -f "${NEW_SITE_CONFIG}"
    
    exit 1
  fi
fi

# Add the domain to the ngrok config if it exists.
if [ -f "${NGROK_CONFIG}" ]; then
  log_info "Adding ${NGROK_START_NAME} to ngrok config."
  
  cat << EOF >> "${NGROK_CONFIG}"
  ${NGROK_START_NAME}:
    proto: http
    addr: 80
    host_header: www.${NEW_SITE_DOMAIN}.test
EOF
fi

# Generate the openssl private key if it doesn't exist
if [ ! -f "${SSL_KEY_FILE}" ]; then
  log_info "Creating the openssl private key at ${SSL_KEY_FILE}."

  openssl genrsa -out "${SSL_KEY_FILE}" 2048

  chmod 640 "${SSL_KEY_FILE}"
else
  log_info "Openssl private key already exists at ${SSL_KEY_FILE}."
fi

# If the working config file doesn't exist, create it
if [ ! -f "${SSL_WORKING_CONF_FILE}" ]; then
  log_info "Initializing the working openssl config file."

  cp "${SSL_DEFAULT_CONF_FILE}" "${SSL_WORKING_CONF_FILE}"
fi

egrep -qi "^DNS.[0-9]+\s*=\s*${NEW_SITE_DOMAIN}.test\s*$" "${SSL_WORKING_CONF_FILE}"
if [[ $? -ne 0 ]]; then
  # Add the new domain to the openssl config
  log_info "Adding the new domain to the openssl config."

  if [[ "$(grep -n "^DNS\." "${SSL_WORKING_CONF_FILE}" | tail -n 1)" =~ ^([0-9]+):DNS\.([0-9]+) ]]; then
    readonly LINE_NUMBER=${BASH_REMATCH[1]}
    readonly DNS_NUMBER=${BASH_REMATCH[2]}

    sed -i "${LINE_NUMBER} a DNS.$((${DNS_NUMBER} + 1)) = ${NEW_SITE_DOMAIN}.test" "${SSL_WORKING_CONF_FILE}"
    sed -i "$((${LINE_NUMBER} + 1)) a DNS.$((${DNS_NUMBER} + 2)) = \*.${NEW_SITE_DOMAIN}.test" "${SSL_WORKING_CONF_FILE}"
  else
    log_warning "Could not add the new domain. DNS entries not found in openssl config!"
  fi
else
  log_warning "The ${NEW_SITE_DOMAIN}.test site already exists in the openssl config."
fi

# Regenerate the cert file
log_info "Regenerating the ssl cert to ensure it has all domains."

readonly SSL_CERT_COUNTRY="${SSL_CERT_COUNTRY:-US}"
readonly SSL_CERT_STATE="${SSL_CERT_STATE:-Virginia}"
readonly SSL_CERT_LOCALITY="${SSL_CERT_LOCALITY}"
readonly SSL_CERT_ORG_NAME="${SSL_CERT_ORG_NAME:-Internet Widgits Pty Ltd}"
readonly SSL_CERT_COMMON_NAME="${SSL_CERT_COMMON_NAME:-WSL - ${WSL_USER}}"
readonly SSL_CERT_SUBJECT="/C=${SSL_CERT_COUNTRY}/ST=${SSL_CERT_STATE}/L=${SSL_CERT_LOCALITY}/O=${SSL_CERT_ORG_NAME}/CN=${SSL_CERT_COMMON_NAME}"

openssl req -new -x509 -key "${SSL_KEY_FILE}" -sha256 -config "${SSL_WORKING_CONF_FILE}" -out "${SSL_CERT_FILE}" -days 3650 -subj "${SSL_CERT_SUBJECT}"
chmod 644 "${SSL_CERT_FILE}"

log_info "Restarting Apache server."

# Restart apache to make the site available.
service apache2 restart

log_info "Domain ${NEW_SITE_DOMAIN} is now available."
