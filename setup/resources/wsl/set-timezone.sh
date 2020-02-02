#!/bin/bash

source "$(dirname "$(dirname "$(readlink -f "${0}")")")/init-resource.sh"

ensure_root

readonly TZ_AREA="${TZ_AREA:-Etc}"
readonly TZ_ZONE="${TZ_ZONE:-UTC}"

# Setup timezone selections
debconf-set-selections <<< "tzdata tzdata/Areas select ${TZ_AREA}"
debconf-set-selections <<< "tzdata tzdata/Zones/${TZ_AREA} select ${TZ_ZONE}"

log_info "Setting system timezone to ${TZ_ZONE}."

# Remove current timezone settings
rm /etc/timezone 2> /dev/null
rm /etc/localtime 2> /dev/null

# Set the timezone
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure tzdata

log_info "System timezone set to ${TZ_ZONE}."
