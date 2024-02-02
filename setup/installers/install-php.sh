#!/bin/bash -l

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_installed "PHPENV" "PHPENV is required but is not found at ${PHPENV_ROOT} or is not loaded. If using sudo, make sure to use a login shell (sudo -i)."
ensure_variable_set "WSL_USER"

REQUESTED_VERSION="${1:-latest}"
if [[ "${REQUESTED_VERSION}" == "latest" ]]; then
  REQUESTED_VERSION="$(phpenv_latest_version)"

  log_info "Latest PHP version resolved to ${REQUESTED_VERSION}."
fi

readonly WSL_USER
readonly PHP_VERSION="${REQUESTED_VERSION}"
readonly PHP_VERSION_COMPARE="${PHP_VERSION/snapshot/.9999}"
readonly PHPENV_ROOT="${PHPENV_ROOT:-/opt/phpenv}"

shift
readonly PHP_OPTIONS=( "$@" )

if [[ ! "${PHP_VERSION}" =~ ^[0-9]+(\.[0-9]+)*(snapshot)?$ ]]; then
  log_error "Version parameter [${PHP_VERSION}] is not in the correct format."
  exit 1
fi

readonly PHP_VERSION_INSTALL=$(phpenv install -l | grep -E "^\s*${PHP_VERSION}(\.[0-9]+)*\s*$" | tail -n 1 | tr -d "[:space:]")

if [[ -z "${PHP_VERSION_INSTALL}" ]]; then
  log_error "Version [${PHP_VERSION}] could not be resolved to an installable version."
  exit 1
fi

ensure_not_installed "phpenv_version-${PHP_VERSION_INSTALL}" "PHP version [${PHP_VERSION_INSTALL}] is already installed."

log_info "Checking and installing needed dependencies."

BUILD_CONFIGURE_OPTIONS=( "${PHP_OPTIONS[@]}" )
BUILD_PKG_CONFIG_PATH=()

# PHP < 7.1.17, 7.2.0 - 7.2.4
# - Need ICU < 61.1
# PHP < 7.4.26, < 8.0.13
# - Need ICU < 68.1
# - breakiterator_class.cpp: conflicting return type: fixed in 7.4.26, 8.0.13
# - collator_sort.c: ‘TRUE’ undeclared: fixed in 7.3.25 and 7.4.12
if version_compare "${PHP_VERSION_COMPARE}" "lt" "7.1.17"; then
  readonly ICU_VERSION_INSTALL="60.3"
elif version_compare "${PHP_VERSION_COMPARE}" "ge" "7.2.0" && version_compare "${PHP_VERSION_COMPARE}" "lt" "7.2.5"; then
  readonly ICU_VERSION_INSTALL="60.3"
elif version_compare "${PHP_VERSION_COMPARE}" "lt" "7.4.26"; then
  readonly ICU_VERSION_INSTALL="67.1"
elif version_compare "${PHP_VERSION_COMPARE}" "ge" "8.0.0" && version_compare "${PHP_VERSION_COMPARE}" "lt" "8.0.13"; then
  readonly ICU_VERSION_INSTALL="67.1"
else
  readonly ICU_VERSION_INSTALL=""
fi
if [[ -n "${ICU_VERSION_INSTALL}" ]]; then
  readonly ICU_SYSTEM_VERSION="$(dpkg -l | egrep "ii\s*libicu-dev(:|\s)" | awk '{print $3}' | cut -d '-' -f 1)"
  readonly ICU_PREFIX="/opt/icu-${ICU_VERSION_INSTALL}"
  USE_CUSTOM_ICU=""
  INSTALL_ICU=""

  log_info "PHP version ${PHP_VERSION_INSTALL} requires ICU version ${ICU_VERSION_INSTALL} or earlier."

  if [[ -z "${ICU_SYSTEM_VERSION}" ]]; then
    log_info "System ICU version not found. Checking for custom ICU version."
    USE_CUSTOM_ICU="yes"
  elif version_compare "${ICU_SYSTEM_VERSION}" "gt" "${ICU_VERSION_INSTALL}"; then
    log_info "System ICU version ${ICU_SYSTEM_VERSION} is too high. Checking for custom ICU version."
    USE_CUSTOM_ICU="yes"
  else
    log_info "System ICU version ${ICU_SYSTEM_VERSION} will be used."
  fi

  if [[ -n "${USE_CUSTOM_ICU}" ]] && [[ ! -e "${ICU_PREFIX}/bin/icu-config" ]]; then
    log_info "ICU version ${ICU_VERSION_INSTALL} not found."
    INSTALL_ICU="yes"
  elif [[ -n "${USE_CUSTOM_ICU}" ]] && [[ -e "${ICU_PREFIX}/bin/icu-config" ]]; then
    log_info "ICU version ${ICU_VERSION_INSTALL} found at ${ICU_PREFIX}. It will be used."
  fi

  if [[ -n "${INSTALL_ICU}" ]]; then
    log_info "ICU version ${ICU_VERSION_INSTALL} will be installed. This may take a few minutes..."

    readonly ICU_RELEASE="${ICU_VERSION_INSTALL/./-}"
    readonly ICU_TMP="/tmp/icu-${ICU_RELEASE}"
    readonly ORIG_DIR="${PWD}"

    # Needed for ICU < 60.3. No harm, so just do it regardless of install version.
    if [[ ! -e "/usr/include/xlocale.h" ]] && [[ -e "/usr/include/locale.h" ]]; then
      ln -s /usr/include/locale.h /usr/include/xlocale.h
    fi

    mkdir -p "${ICU_TMP}"
    curl -sL -o "${ICU_TMP}/icu.tar.gz" "https://github.com/unicode-org/icu/archive/release-${ICU_RELEASE}.tar.gz"
    tar -xf "${ICU_TMP}/icu.tar.gz" -C "${ICU_TMP}"
    cd "${ICU_TMP}/icu-release-${ICU_RELEASE}/icu4c/source/"
    ./runConfigureICU Linux --prefix="${ICU_PREFIX}"
    make -j4
    make install
    cd -
    rm -rf "${ICU_TMP}"

    cat << EOF > "/etc/ld.so.conf.d/icu-${ICU_VERSION_INSTALL}.conf"
${ICU_PREFIX}/lib
EOF
    ldconfig
  fi

  if [[ -n "${USE_CUSTOM_ICU}" ]]; then
    # PHP 7.4 removed --with-icu-dir and uses pkg-config instead
    if version_compare "${PHP_VERSION_COMPARE}" "lt" "7.4.0"; then
      BUILD_CONFIGURE_OPTIONS+=("--with-icu-dir=${ICU_PREFIX}")
    else
      BUILD_PKG_CONFIG_PATH+=("${ICU_PREFIX}/lib/pkgconfig")
    fi
  fi
fi

# PHP < 7.0.19
# - Need OpenSSL 1.0
# PHP >= 7.0.19 and < 8.1.0
# - Need OpenSSL 1.1
if version_compare "${PHP_VERSION_COMPARE}" "lt" "8.1.0"; then
  if version_compare "${PHP_VERSION_COMPARE}" "lt" "7.0.19"; then
    readonly OPENSSL_VERSION_INSTALL="1.0.2u"
  else
    readonly OPENSSL_VERSION_INSTALL="1.1.1s"
  fi
  readonly OPENSSL_SYSTEM_VERSION="$(dpkg -l | egrep "ii\s*openssl\s+" | awk '{print $3}' | cut -d '-' -f 1)"
  readonly OPENSSL_PREFIX="/opt/openssl-${OPENSSL_VERSION_INSTALL}"
  USE_CUSTOM_OPENSSL=""
  INSTALL_OPENSSL=""

  log_info "PHP version ${PHP_VERSION_INSTALL} requires OPENSSL version ${OPENSSL_VERSION_INSTALL} or earlier."

  if [[ -z "${OPENSSL_SYSTEM_VERSION}" ]]; then
    log_info "System OPENSSL version not found. Checking for custom OPENSSL version."
    USE_CUSTOM_OPENSSL="yes"
  elif version_compare "${OPENSSL_SYSTEM_VERSION}" "gt" "${OPENSSL_VERSION_INSTALL}"; then
    log_info "System OPENSSL version ${OPENSSL_SYSTEM_VERSION} is too high. Checking for custom OPENSSL version."
    USE_CUSTOM_OPENSSL="yes"
  else
    log_info "System OPENSSL version ${OPENSSL_SYSTEM_VERSION} will be used."
  fi

  if [[ -n "${USE_CUSTOM_OPENSSL}" ]] && [[ ! -e "${OPENSSL_PREFIX}/bin/openssl" ]]; then
    log_info "OPENSSL version ${OPENSSL_VERSION_INSTALL} not found."
    INSTALL_OPENSSL="yes"
  elif [[ -n "${USE_CUSTOM_OPENSSL}" ]] && [[ -e "${OPENSSL_PREFIX}/bin/openssl" ]]; then
    log_info "OPENSSL version ${OPENSSL_VERSION_INSTALL} found at ${OPENSSL_PREFIX}. It will be used."
  fi

  if [[ -n "${INSTALL_OPENSSL}" ]]; then
    log_info "Installing OPENSSL version ${OPENSSL_VERSION_INSTALL}. This may take a few minutes..."

    readonly OPENSSL_TMP="/tmp/openssl-${OPENSSL_VERSION_INSTALL}"

    mkdir -p "${OPENSSL_TMP}"
    curl -sL -o "${OPENSSL_TMP}/openssl.tar.gz" "https://www.openssl.org/source/openssl-${OPENSSL_VERSION_INSTALL}.tar.gz"
    tar -xf "${OPENSSL_TMP}/openssl.tar.gz" -C "${OPENSSL_TMP}"
    cd "${OPENSSL_TMP}/openssl-${OPENSSL_VERSION_INSTALL}/"
    ./config shared --prefix="${OPENSSL_PREFIX}" --openssldir="${OPENSSL_PREFIX}"
    make
    make install
    cd -
    rm -rf "${OPENSSL_TMP}"

    # Add a new linker config with the new openssl lib directory. Without
    # this, the new openssl executable can't find the shared libraries.
    cat << EOF > "/etc/ld.so.conf.d/openssl-${OPENSSL_VERSION_INSTALL}.conf"
${OPENSSL_PREFIX}/lib
EOF
    ldconfig
  fi

  if [[ -n "${USE_CUSTOM_OPENSSL}" ]]; then
    BUILD_CONFIGURE_OPTIONS+=("--with-openssl-dir=${OPENSSL_PREFIX}")
    BUILD_PKG_CONFIG_PATH+=("${OPENSSL_PREFIX}/lib/pkgconfig")
  fi
fi

# PHP < 7.0.23, 7.1.0 - 7.1.8
# - Need to symlink curl
if version_compare "${PHP_VERSION_COMPARE}" "lt" "7.0.23"; then
  log_info "PHP version ${PHP_VERSION_INSTALL} expects curl in a certain location."

  if [[ -e /usr/include/x86_64-linux-gnu/curl ]] && [[ ! -e /usr/local/include/curl ]]; then
    log_info "Creating curl symlink to expected location."
    ln -s /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl
  elif [[ ! -e /usr/include/x86_64-linux-gnu/curl ]]; then
    log_info "System curl not found in expected location."
  elif [[ -e /usr/local/include/curl ]]; then
    log_info "Curl already found in expected location."
  fi
elif version_compare "${PHP_VERSION_COMPARE}" "ge" "7.1.0" && version_compare "${PHP_VERSION_COMPARE}" "le" "7.1.8"; then
  log_info "PHP version ${PHP_VERSION_INSTALL} expects curl in a certain location."

  if [[ -e /usr/include/x86_64-linux-gnu/curl ]] && [[ ! -e /usr/local/include/curl ]]; then
    log_info "Creating curl symlink to expected location."
    ln -s /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl
  elif [[ ! -e /usr/include/x86_64-linux-gnu/curl ]]; then
    log_info "System curl not found in expected location."
  elif [[ -e /usr/local/include/curl ]]; then
    log_info "Curl already found in expected location."
  fi
fi

BUILD_CONFIGURE_OPTIONS="${BUILD_CONFIGURE_OPTIONS[*]}"
BUILD_PKG_CONFIG_PATH="$(IFS=":"; echo "${BUILD_PKG_CONFIG_PATH[*]}")"

log_info "Installing PHP ${PHP_VERSION_INSTALL} using PHPENV in ${PHPENV_ROOT}. This may take a few minutes..."

# Install PHP using PHPENV.
PHP_BUILD_CONFIGURE_OPTS="${BUILD_CONFIGURE_OPTIONS}" PKG_CONFIG_PATH="${BUILD_PKG_CONFIG_PATH}" phpenv install ${PHP_VERSION_INSTALL}

if [[ "$?" == "0" ]]; then
  log_info "PHP version ${PHP_VERSION_INSTALL} installed successfully!"
else
  log_error "PHP version ${PHP_VERSION_INSTALL} was not installed successfully."

  exit 1
fi

readonly PHP_VERSION_ROOT="${PHPENV_ROOT}/versions/${PHP_VERSION_INSTALL}"

if [[ -z "${PHPENV_PHP_LOG_DIR}" ]]; then
  readonly PHPENV_PHP_LOG_DIR="${PHP_VERSION_ROOT}/var/log"
  readonly PHPENV_PHP_LOG_FILENAME="php.log"
else
  readonly PHPENV_PHP_LOG_DIR="${PHPENV_PHP_LOG_DIR}"
  readonly PHPENV_PHP_LOG_FILENAME="php-${PHP_VERSION_INSTALL}.log"
fi

readonly PHPENV_PHP_LOG_FILE="${PHPENV_PHP_LOG_DIR}/${PHPENV_PHP_LOG_FILENAME}"

if [[ ! -d "${PHPENV_PHP_LOG_DIR}" ]]; then
  log_info "Creating PHP log directory at [${PHPENV_PHP_LOG_DIR}]."

  mkdir -p ${PHPENV_PHP_LOG_DIR}
fi

log_info "Creating PHP error log file at [${PHPENV_PHP_LOG_FILE}]."

# Create the log file and update the permissions.
touch "${PHPENV_PHP_LOG_FILE}"
chown "${WSL_USER}":"${WSL_USER}" "${PHPENV_PHP_LOG_FILE}"
chmod 666 "${PHPENV_PHP_LOG_FILE}"

log_info "Enabling the PHP error log file."

# Create the error log ini file and enable it for all SAPIs.
echo "error_log = \"${PHPENV_PHP_LOG_FILE}\"" > "${PHP_VERSION_ROOT}/etc/conf.d/error_log.ini"

# Create the display errors ini file and enable it for all SAPIs.
cat << EOF > "${PHP_VERSION_ROOT}/etc/conf.d/display_errors.ini"
display_errors = On
display_startup_errors = On
EOF

log_info "Configuring PHP-FPM for PHP ${PHP_VERSION_INSTALL}."

readonly PHPFPM_ROOT="${PHP_VERSION_ROOT}"
readonly PHPFPM_SOCK="var/run/php-fpm.sock"
readonly PHPFPM_SERVICE_FILE="${PHPFPM_ROOT}/etc/init.d/php-fpm"
readonly PHPFPM_SERVICE_NAME="php-fpm-${PHP_VERSION_INSTALL}"

# PHP-FPM config location changed in 7.0.
# See: https://github.com/php/php-src/blob/php-7.0.0/sapi/fpm/Makefile.frag
if [[ -f "${PHPFPM_ROOT}/etc/php-fpm.d/www.conf" ]]; then
  readonly PHPFPM_CONF="${PHPFPM_ROOT}/etc/php-fpm.d/www.conf"
elif [[ -f "${PHPFPM_ROOT}/etc/php-fpm.conf" ]]; then
  readonly PHPFPM_CONF="${PHPFPM_ROOT}/etc/php-fpm.conf"
fi

if [[ -n "${PHPFPM_CONF}" ]]; then
  log_info "Updating PHP-FPM www pool config at ${PHPFPM_CONF}."

  # Change the default PHP-FPM user to the WSL_USER
  sed -i "s#^user\s*=.*#user = ${WSL_USER}#g" "${PHPFPM_CONF}"
  sed -i "s#^group\s*=.*#group = ${WSL_USER}#g" "${PHPFPM_CONF}"

  # Update the PHP-FPM service to use a unix socket instead of TCP address.
  # The socket path is relative to the PHP version being installed.
  sed -i "s#^listen\s*=.*#listen = ${PHPFPM_SOCK}#g" "${PHPFPM_CONF}"
  sed -i "s#^;listen.owner\s*=.*#listen.owner = ${WSL_USER}#g" "${PHPFPM_CONF}"
  sed -i "s#^;listen.group\s*=.*#listen.group = ${WSL_USER}#g" "${PHPFPM_CONF}"
else
  log_warning "PHP-FPM config file not found. It will need to be found and manually edited."
fi

log_info "Installing PHP-FPM service script as ${PHPFPM_SERVICE_NAME}."

cp "${PHPFPM_SERVICE_FILE}" "/etc/init.d/${PHPFPM_SERVICE_NAME}"

log_info "PHP version ${PHP_VERSION_INSTALL} install complete!"
