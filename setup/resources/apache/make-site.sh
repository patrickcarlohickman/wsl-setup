#!/bin/bash

source "$(dirname "$(dirname "$(readlink -f "${0}")")")/init-resource.sh"

function usage {
  echo "Usage: $(script_name) < domain > [ directory [ ngrok_start_name ] ]"
}

readonly NEW_SITE_DOMAIN="${1}"
readonly NEW_SITE_DIRECTORY="${2:-${1}/public}"
readonly NGROK_START_NAME="${3:-${1}}"

readonly VHOST_DIRECTORY="${VHOST_DIRECTORY:-/var/www/vhost}"
readonly SITES_DIRECTORY="/etc/apache2/sites-available"
readonly STUB_FILENAME="apache-site-stub.conf"
readonly STUB_DOMAIN_PLACEHOLDER="stub-domain"
readonly STUB_VHOST_DIRECTORY_PLACEHOLDER="stub-vhost"
readonly STUB_DIRECTORY_PLACEHOLDER="stub-folder"
readonly NGROK_DIRECTORY="${NGROK_DIRECTORY:-/opt/ngrok}"
readonly NGROK_CONFIG="${NGROK_DIRECTORY}/conf/ngrok.yml"
readonly STUB_FILE="$(script_dir)/${STUB_FILENAME}"
readonly NEW_SITE_CONFIG="${SITES_DIRECTORY}/${NEW_SITE_DOMAIN}.conf"

if [[ $# -lt 1 || "${NEW_SITE_DOMAIN}" = "-h" || "${NEW_SITE_DOMAIN}" = "--help" ]]; then
  usage
  exit 1
fi

ensure_root
ensure_installed "Apache"
ensure_file_exists "${STUB_FILE}"
ensure_file_missing "${NEW_SITE_CONFIG}"

log_info "Setting up new site config file."

# Copy the stub template file to the new site config file.
cp "${STUB_FILE}" "${NEW_SITE_CONFIG}"

# Replace the stub placeholders with the new site values.
sed -i "s#${STUB_DOMAIN_PLACEHOLDER}#${NEW_SITE_DOMAIN}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_VHOST_DIRECTORY_PLACEHOLDER}#${VHOST_DIRECTORY}#g" "${NEW_SITE_CONFIG}"
sed -i "s#${STUB_DIRECTORY_PLACEHOLDER}#${NEW_SITE_DIRECTORY}#g" "${NEW_SITE_CONFIG}"

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

log_info "Restarting Apache server."

# Restart apache to make the site available.
service apache2 restart

log_info "Domain ${NEW_SITE_DOMAIN} is now available."
