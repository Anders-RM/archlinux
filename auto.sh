#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/auto.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Execute scripts and log their output
execute_and_log() {
    local script="$1"
    log "Executing $script"
    if ./"$script" | tee -a "$LOG_FILE"; then
        log "$script executed successfully"
    else
        log "Error executing $script"
        exit 1
    fi
}

# List of scripts to execute
scripts=(
    "app_install.sh"
    "sddm_kdm_Config.sh"
    "update_service.sh"
    #"appimage.sh"
)

for script in "${scripts[@]}"; do
    execute_and_log "$script"
done

# Final updates and reboot
log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"