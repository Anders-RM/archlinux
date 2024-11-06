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

TEMP_DIR=~/.temp
APPIMAGE_LOCATION="$TEMP_DIR/appimage"
APPIMAGE_URL="https://cdn.filen.io/desktop/release/filen_x86_64.AppImage"
APPIMAGE_FILE="$APPIMAGE_LOCATION/filen_x86_64.AppImage"
EXTRACT_DIR="$APPIMAGE_LOCATION/filen_appimage"
INSTALL_DIR="/opt/filen_appimage"
DESKTOP_FILE_PATH="$INSTALL_DIR/filen-desktop.desktop"
PACKAGE_JSON_PATH="$INSTALL_DIR/resources/app/package.json"

# Function to check if an update is needed
check_for_update() {
    # Download latest version to a temporary file to compare versions
    TEMP_APPIMAGE="$APPIMAGE_LOCATION/temp_filen_x86_64.AppImage"
    log "Checking for updates..."
    curl -L -o "$TEMP_APPIMAGE" "$APPIMAGE_URL" --silent --show-error

    if [ -f "$PACKAGE_JSON_PATH" ]; then
        CURRENT_VERSION=$(jq -r '.version' "$PACKAGE_JSON_PATH")
        TEMP_VERSION=$(./"$TEMP_APPIMAGE" --appimage-extract-and-run jq -r '.version' "$PACKAGE_JSON_PATH")

        if [ "$CURRENT_VERSION" == "$TEMP_VERSION" ]; then
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

run_command "mkdir -p $APPIMAGE_LOCATION" "Creating temporary directory"

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

run_command "rm -rf $APPIMAGE_LOCATION" "Removing temporary directory"
# Launch the Filen application
run_command "gio launch /usr/share/applications/filen-desktop.desktop" "Launching Filen"

exit 0
