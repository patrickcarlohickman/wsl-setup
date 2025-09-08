#!/bin/bash -l

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "PHPENV"

readonly PHPENV_ROOT="${PHPENV_ROOT:-/opt/phpenv}"
readonly PHPENV_PROFILE="${PHPENV_PROFILE:-/etc/profile.d/phpenv.sh}"
readonly PHPENV_PECL_BUILD="${PHPENV_PECL_BUILD}"

log_info "Installing PHPENV globally. This may take a few minutes..."

log_info "Downloading and running installer."

# Install PHPENV with the proper PHPENV_ROOT variable.
curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | PHPENV_ROOT="${PHPENV_ROOT}" bash

# Remove composer plugin so we can install/use composer globally.
if [[ -d "${PHPENV_ROOT}/plugins/phpenv-composer" ]]; then
  log_info "Removing phpenv-composer plugin."

  rm -rf phpenv-composer "${PHPENV_ROOT}/plugins/phpenv-composer"
fi

if [[ -n "${PHPENV_PECL_BUILD}" ]]; then
  log_info "Installing pecl-build plugin."

  git clone "${PHPENV_PECL_BUILD}" "${PHPENV_ROOT}/plugins/pecl-build"
fi

log_info "Setting PHPENV directory permissions."

# Make sure the PHPENV install dir exists with global permissions.
if [[ -d "${PHPENV_ROOT}" ]]; then
  chmod 777 "${PHPENV_ROOT}"
fi

log_info "Initializing PHPENV."

export PHPENV_ROOT
if [ -d "${PHPENV_ROOT}" ]; then
  export PATH="${PHPENV_ROOT}/bin:${PATH}"
  eval "$(phpenv init -)"
fi

log_info "Setting PHPENV subdirectory permissions."

# Make sure the PHPENV shims and versions directories have global permissions.
if [[ -d "${PHPENV_ROOT}/shims" ]]; then
  chmod 777 "${PHPENV_ROOT}/shims"
fi
if [[ -d "${PHPENV_ROOT}/versions" ]]; then
  chmod 777 "${PHPENV_ROOT}/versions"
fi

log_info "Creating PHPENV profile file."

cat << EOF > "${PHPENV_PROFILE}"
export PHPENV_ROOT="${PHPENV_ROOT}"
if [ -d "\${PHPENV_ROOT}" ]; then
  export PATH="\${PHPENV_ROOT}/bin:\${PATH}"
  COMPOSER_ALLOW_SUPERUSER=1 eval "\$(phpenv init -)"
fi
EOF

log_info "Installing common dependencies for building PHP."

# Install the dependencies from php-build
${PHPENV_ROOT}/plugins/php-build/install-dependencies.sh

# Install additional dependencies missed by php-build
apt-get -yqq update
DEBIAN_FRONTEND=noninteractive apt-get -y install libltdl-dev --no-install-recommends

# Generate, modify, and install the icu-config script (needed for intl).
readonly ICU_VERSION="$(dpkg -l | egrep "ii\s*libicu-dev(:|\s)" | awk '{print $3}' | cut -d '-' -f 1)"
if [[ -n "${ICU_VERSION}" ]] && [[ -z "$(which icu-config)" ]]; then
  readonly ICU_RELEASE="${ICU_VERSION/./-}"
  readonly ICU_TMP="/tmp/icu"
  readonly ICU_PREFIX="${ICU_TMP}/icu-${ICU_RELEASE}"

  mkdir -p "${ICU_TMP}"
  curl -sL -o "${ICU_TMP}/icu.tar.gz" "https://github.com/unicode-org/icu/archive/release-${ICU_RELEASE}.tar.gz"
  tar -xf "${ICU_TMP}/icu.tar.gz" -C "${ICU_TMP}"
  cd "${ICU_TMP}/icu-release-${ICU_RELEASE}/icu4c/source/"
  ./runConfigureICU Linux --prefix="${ICU_PREFIX}"
  make -j4
  make install
  # update icu-config
  # - change prefix to /usr
  sed -i "s/^default_prefix=.*$/default_prefix=\"\/usr\"/g" "${ICU_PREFIX}/bin/icu-config"
  # - add /x86_64-linux-gnu to libdir
  sed -E -i "s/^libdir=\"(.*)\"$/libdir=\"\1\/x86_64-linux-gnu\"/g" "${ICU_PREFIX}/bin/icu-config"
  cp "${ICU_PREFIX}/bin/icu-config" /usr/bin/icu-config
  chown root:root /usr/bin/icu-config
  cd -
  rm -rf "${ICU_TMP}"
fi

log_info "PHPENV install complete!"
