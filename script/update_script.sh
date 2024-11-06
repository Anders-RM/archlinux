#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="/usr/local/bin/update"  # Get the directory of the script
LOG_FILE="$SCRIPT_DIR/update_script.log"         # Define the log file path

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"  # Create the directory for the log file if it doesn't exist
touch "$LOG_FILE"                  # Create the log file if it doesn't exist

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"  # Log the message with a timestamp
}

# General function to run commands and log output
run_command() {
    if eval "$1"; then
        log "$2 succeeded"  # Log success message if the command succeeds
    else
        log "$2 failed"     # Log failure message if the command fails
        exit 1              # Exit the script with an error code
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
run_command "flatpak update -y" "Flatpak update"
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
run_command "sudo snap refresh" "Snap update"
log "Snap update completed."

exit 0
