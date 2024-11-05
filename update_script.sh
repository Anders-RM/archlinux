#!/bin/bash
# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/update_script.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}


# Update pacman packages
log "Starting pacman update..."
sudo pacman -Syyu --noconfirm
log "Pacman update completed."

# Update AUR packages
log "Starting yay update..."
yay -Syyu --noconfirm
log "Yay update completed."

# Update Flatpak packages
log "Starting Flatpak update..."
flatpak update -y 
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
sudo snap refresh
log "Snap update completed."

# Log completion of all updates
log "All updates completed successfully."

#run_command "./appimage.sh" "AppImage update"

exit 0