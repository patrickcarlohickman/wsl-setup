#!/bin/bash

source "$(dirname "$(dirname "$(readlink -f "${0}")")")/init-resource.sh"

ensure_root
ensure_installed "MySQL"

log_info "Running SQL statements in create-databases-mysql.sql."

mysql < "$(script_dir)/create-databases-mysql.sql"
