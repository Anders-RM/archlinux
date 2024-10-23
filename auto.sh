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

# Default value for arguments
EXECUTE_VM=true
EXECUTE_GAMING=true

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-vm) EXECUTE_VM=false ;;
        --no-gaming) EXECUTE_GAMING=false ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# List of scripts to execute
scripts=(
    "app_install.sh"
    "sddm_kdm_Config.sh"
    "update_service.sh"
    "appimage.sh"
    "bauh.sh"
)

# Conditionally add vm.sh to the list of scripts
if [ "$EXECUTE_VM" = true ]; then
    scripts+=("vm.sh")
fi

if [ "$EXECUTE_gaming" = true ]; then
    scripts+=("gaming.sh")
fi

for script in "${scripts[@]}"; do
    execute_and_log "$script"
done

# Final updates and reboot
log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"