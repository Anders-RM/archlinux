#!/bin/bash
# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/update_script.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
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

# Update pacman packages
log "Starting pacman update..."
run_command "sudo pacman -Syyu --noconfirm" "Pacman update"
log "Pacman update completed."

# Update AUR packages
log "Starting yay update..."
run_command "yay -Syyu --noconfirm" "Yay update"
log "Yay update completed."

# Update Flatpak packages
log "Starting Flatpak update..."
flatpak update -y 
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
run_command "sudo snap refresh" "Snap update"
log "Snap update completed."

# Log completion of all updates
log "All updates completed successfully."

run_command "./appimage.sh" "AppImage update"

exit 0