#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "ngrok"
ensure_variable_set "WSL_USER"
resolve_system_dependencies "wget" "unzip" "tar"
ensure_system_dependencies "wget" "unzip" "tar"

readonly WSL_USER
readonly NGROK_DIRECTORY="${NGROK_DIRECTORY:-/opt/ngrok}"
readonly NGROK_DOWNLOAD_LINK="${NGROK_DOWNLOAD_LINK:-https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz}"
readonly NGROK_AUTH_TOKEN="${NGROK_AUTH_TOKEN}"
readonly NGROK_DOWNLOAD_FILE="${NGROK_DOWNLOAD_LINK##*/}"
readonly NGROK_DOWNLOAD_FILE_EXT="${NGROK_DOWNLOAD_FILE##*.}"
readonly NGROK_CONFIG="${NGROK_DIRECTORY}/conf/ngrok.yml"
readonly WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"

log_info "Installing ngrok. This may take a few minutes..."

log_info "Creating ngrok directory."

# Create the ngrok directory.
mkdir -p "${NGROK_DIRECTORY}"

log_info "Downloading ngrok archive file."

# Download the ngrok archive file.
wget -q "${NGROK_DOWNLOAD_LINK}"

log_info "Decompressing and removing ngrok archive file."

# Decompress the downloaded file and remove it.
if [[ "${NGROK_DOWNLOAD_FILE_EXT}" == "zip" ]]; then
    unzip -q "${NGROK_DOWNLOAD_FILE}" -d "${NGROK_DIRECTORY}"
else
    tar -xvzf "${NGROK_DOWNLOAD_FILE}" -C "${NGROK_DIRECTORY}"
fi
rm -f "${NGROK_DOWNLOAD_FILE}"

log_info "Moving the ngrok executable into place."

# Move the executable into place.
mv "${NGROK_DIRECTORY}/ngrok" "/usr/local/bin/"

log_info "Initializing the ngrok config."

# Create the ngrok config directory.
mkdir -p "${NGROK_DIRECTORY}/conf"

# Create the base config file.
touch "${NGROK_CONFIG}"

if [[ -n "${NGROK_AUTH_TOKEN}" ]]; then
    cat << EOF >> "${NGROK_CONFIG}"
authtoken: ${NGROK_AUTH_TOKEN}
EOF
fi

cat << EOF >> "${NGROK_CONFIG}"
version: 2
tunnels:
EOF

log_info "Creating the user's symbolic link to the ngrok config."

# The default location of the ngrok config file is ${HOME}/ngrok2/ngrok.yml.
# Create the default ngrok config file in the WSL_USER's home directory
# as a symbolic link to the globally installed config file.
sudo -u "${WSL_USER}" mkdir -m 777 "${WSL_USER_DIRECTORY}/.ngrok2"
sudo -u "${WSL_USER}" ln -s "${NGROK_CONFIG}" "${WSL_USER_DIRECTORY}/.ngrok2/ngrok.yml"

log_info "ngrok install complete!"
