#!/bin/bash

LOGFILE="/var/log/update_script.log"

# Ensure the log file exists
touch "$LOGFILE"

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

TEMP_DIR=~/.temp/appimage
APPIMAGE_URL="https://cdn.filen.io/desktop/release/filen_x86_64.AppImage"
APPIMAGE_FILE="$TEMP_DIR/filen_x86_64.AppImage"
EXTRACT_DIR="$TEMP_DIR/filen_appimage"
INSTALL_DIR="/opt/filen_appimage"
DESKTOP_FILE_PATH="$INSTALL_DIR/filen-desktop.desktop"

# Function to check if an update is needed
check_for_update() {
    # Download latest version to a temporary file to compare versions
    TEMP_APPIMAGE="$TEMP_DIR/temp_filen_x86_64.AppImage"
    log "Checking for updates..."
    curl -L -o "$TEMP_APPIMAGE" "$APPIMAGE_URL" --silent --show-error

    if [ -f "$APPIMAGE_FILE" ]; then
        if cmp -s "$APPIMAGE_FILE" "$TEMP_APPIMAGE"; then
            log "No update available. The AppImage is already up-to-date."
            rm "$TEMP_APPIMAGE"
            exit 0
        else
            log "Update found. Proceeding with update..."
            mv "$TEMP_APPIMAGE" "$APPIMAGE_FILE"
        fi
    else
        log "AppImage not found. Downloading new version."
        mv "$TEMP_APPIMAGE" "$APPIMAGE_FILE"
    fi
}

run_command "mkdir -p $TEMP_DIR" "Creating temporary directory"

# Run the update check function
check_for_update

# Make the downloaded AppImage executable
log "Making Filen AppImage executable"
run_command "chmod +x \"$APPIMAGE_FILE\"" "Making Filen AppImage executable"

# Remove old installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    log "Removing old installation at $INSTALL_DIR"
    run_command "sudo rm -rf \"$INSTALL_DIR\"" "Removing old installation"
fi

# Extract the new AppImage
log "Extracting Filen AppImage"
run_command "$APPIMAGE_FILE --appimage-extract" "Extracting Filen AppImage"

# Move the extracted files to /opt
log "Moving extracted files to $INSTALL_DIR"
run_command "sudo mv squashfs-root \"$INSTALL_DIR\"" "Moving extracted files to /opt"
run_command "sudo chmod 775 \"$INSTALL_DIR\"" "Changing permissions"
run_command "sudo chown root:root \"$INSTALL_DIR\"" "Changing ownership"
log "Filen AppImage downloaded and extracted successfully"

# Update the .desktop file for the correct path and move to applications directory
log "Updating .desktop file"
run_command "sudo sed -i 's|Exec=AppRun --no-sandbox %U|Exec=$INSTALL_DIR/AppRun %U|' \"$INSTALL_DIR/filen-desktop.desktop\"" "Updating .desktop file"
run_command "sudo mv \"$INSTALL_DIR/filen-desktop.desktop\" /usr/share/applications/filen-desktop.desktop" "Moving .desktop file to /usr/share/applications/"
run_command "sudo cp \"$INSTALL_DIR/filen-desktop.png\" /usr/share/icons/filen-desktop.png" "Copying icon to /usr/share/icons"

# Set up autostart if not already configured
mkdir -p "$HOME/.config/autostart"
run_command "cp /usr/share/applications/filen-desktop.desktop $HOME/.config/autostart/filen-desktop.desktop" "Copying .desktop file to autostart"

# Ensure user directory exists and create shortcut
run_command "mkdir -p \"$HOME/filen\"" "Creating filen directory"
run_command "ln -sf \"$HOME/filen\" \"$HOME/Desktop/Filen\"" "Creating desktop shortcut"

log "Filen AppImage updated and installed successfully"

# Launch the Filen application
run_command "gio launch /usr/share/applications/filen-desktop.desktop" "Launching Filen"

exit 0