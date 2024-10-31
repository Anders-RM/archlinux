#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/reflector.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# General function to run commands and log output
run_command() {
    if eval "$1"; then
        log "$2 succeeded"
    else
        log "$2 failed"
        exit 1
    fi
}

run_command "sudo pacman -Syyu --noconfirm" "Updating system"
run_command "sudo pacman -S reflector --noconfirm" "Installing reflector"

# Modify the reflector configuration file
REFLECTOR_CONF="/etc/xdg/reflector/reflector.conf"
sudo sed -i 's/^--country.*$/  --country DE,SE,DK/' "$REFLECTOR_CONF"
sudo sed -i 's/^--sort.*$/--sort rate/' "$REFLECTOR_CONF"

log "Modified reflector configuration"

exit 0