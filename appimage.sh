#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/AppImage.log"

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

# Download and extract Filen AppImage
APPIMAGE_URL="https://cdn.filen.io/desktop/release/filen_x86_64.AppImage"
APPIMAGE_FILE="$SCRIPT_DIR/filen_x86_64.AppImage"
EXTRACT_DIR="$SCRIPT_DIR/filen_appimage"
DESKTOP_FILE_PATH="/opt/filen_appimage/filen-desktop.desktop"

log "Downloading Filen AppImage"
run_command "curl -L -o \"$APPIMAGE_FILE\" \"$APPIMAGE_URL\"" "Downloading Filen AppImage"

log "Making Filen AppImage executable"
run_command "chmod +x \"$APPIMAGE_FILE\"" "Making Filen AppImage executable"

log "Extracting Filen AppImage"
run_command "\"$APPIMAGE_FILE\" --appimage-extract" "Extracting Filen AppImage"

log "Moving extracted files to $EXTRACT_DIR"
run_command "mv squashfs-root \"$EXTRACT_DIR\"" "Moving extracted files"

run_command "sudo mv $EXTRACT_DIR /opt/" "Moving extracted files to /opt/"
run_command "sudo chmod 775 /opt/filen_appimage/" "Changing permissions"
run_command "sudo chown root:root /opt/filen_appimage/" "Changing ownership"
log "Filen AppImage downloaded and extracted successfully"

# Use sed to modify the Exec line
run_command "sudo sed -i 's|Exec=AppRun --no-sandbox %U|Exec=/opt/filen_appimage/AppRun %U|' \"$DESKTOP_FILE_PATH\"" "Modifying .desktop file"
run_command "sudo mv \"$DESKTOP_FILE_PATH\" /usr/share/applications/filen-desktop.desktop" "Moving .desktop file to /usr/share/applications/"
run_command "sudo cp /opt/filen_appimage/filen-desktop.png /usr/share/icons/filen-desktop.png" "Copying icon to /usr/share/icons"
# Ensure the autostart directory exists
mkdir -p "$HOME/.config/autostart"
run_command "sudo cp /usr/share/applications/filen-desktop.desktop $HOME/.config/autostart/filen-desktop.desktop" "Copying .desktop file to autostart"
#dosn't work
#run_command "sudo cp /usr/share/applications/filen-desktop.desktop $HOME/desktop/filen-desktop.desktop" "Copying .desktop file to desktop"

exit 0