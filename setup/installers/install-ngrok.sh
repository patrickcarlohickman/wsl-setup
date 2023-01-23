#!/bin/bash

source "$(dirname "$(readlink -f "${0}")")/init-install.sh"

ensure_root
ensure_not_installed "ngrok"
ensure_variable_set "WSL_USER"
resolve_system_dependencies "wget" "unzip"
ensure_system_dependencies "wget" "unzip"

readonly WSL_USER
readonly NGROK_DIRECTORY="${NGROK_DIRECTORY:-/opt/ngrok}"
readonly NGROK_DOWNLOAD_LINK="${NGROK_DOWNLOAD_LINK:-https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip}"
readonly NGROK_DOWNLOAD_FILE="${NGROK_DOWNLOAD_LINK##*/}"
readonly WSL_USER_DIRECTORY="$(wsl_user_directory "${WSL_USER}")"

log_info "Installing ngrok. This may take a few minutes..."

log_info "Creating ngrok directory."

# Create the ngrok directory.
mkdir -p "${NGROK_DIRECTORY}"

log_info "Downloading ngrok zip file."

# Download the ngrok zip file.
wget -q "${NGROK_DOWNLOAD_LINK}"

log_info "Unzipping and removing ngrok zip file."

# Unzip the downloaded file and remove it.
unzip -q "${NGROK_DOWNLOAD_FILE}" -d "${NGROK_DIRECTORY}"
rm -f "${NGROK_DOWNLOAD_FILE}"

log_info "Moving the ngrok executable into place."

# Move the executable into place.
mv "${NGROK_DIRECTORY}/ngrok" "/usr/local/bin/"

log_info "Initializing the ngrok config."

# Create the ngrok config directory.
mkdir -p "${NGROK_DIRECTORY}/conf"

# Start the base config file.
echo "tunnels:" > "${NGROK_DIRECTORY}/conf/ngrok.yml"

log_info "Creating the user's symbolic link to the ngrok config."

# The default location of the ngrok config file is ${HOME}/ngrok2/ngrok.yml.
# Create the default ngrok config file in the WSL_USER's home directory
# as a symbolic link to the globally installed config file.
sudo -u "${WSL_USER}" mkdir -m 777 "${WSL_USER_DIRECTORY}/.ngrok2"
sudo -u "${WSL_USER}" ln -s "${NGROK_DIRECTORY}/conf/ngrok.yml" "${WSL_USER_DIRECTORY}/.ngrok2/ngrok.yml"

log_info "ngrok install complete!"
