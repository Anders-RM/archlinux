#!/bin/bash
# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/update_script.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"

# Update pacman packages
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting pacman update..." | tee -a "$LOG_FILE"
sudo pacman -Syyu --noconfirm
echo "$(date '+%Y-%m-%d %H:%M:%S') - Pacman update completed." | tee -a "$LOG_FILE"

# Update AUR packages
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting yay update..." | tee -a "$LOG_FILE"
yay -Syyu --noconfirm
echo "$(date '+%Y-%m-%d %H:%M:%S') - Yay update completed." | tee -a "$LOG_FILE"

# Update Flatpak packages
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Flatpak update..." | tee -a "$LOG_FILE"
flatpak update -y 
echo "$(date '+%Y-%m-%d %H:%M:%S') - Flatpak update completed." | tee -a "$LOG_FILE"

# Update Snap packages
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting Snap update..." | tee -a "$LOG_FILE"
sudo snap refresh
echo "$(date '+%Y-%m-%d %H:%M:%S') - Snap update completed." | tee -a "$LOG_FILE"

# log completion of all updates
echo "$(date '+%Y-%m-%d %H:%M:%S') - All updates completed successfully." | tee -a "$LOG_FILE"

./appimage.sh

exit 0
