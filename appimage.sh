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

# URL of the Filen AppImage
APPIMAGE_URL="https://cdn.filen.io/desktop/release/filen_x86_64.AppImage"
# Path to save the downloaded AppImage
APPIMAGE_FILE="$SCRIPT_DIR/filen_x86_64.AppImage"
# Directory to extract the AppImage
EXTRACT_DIR="$SCRIPT_DIR/filen_appimage"
# Path to the .desktop file inside the extracted AppImage
DESKTOP_FILE_PATH="/opt/filen_appimage/filen-desktop.desktop"

# Download the Filen AppImage
log "Downloading Filen AppImage"
run_command "curl -L -o \"$APPIMAGE_FILE\" \"$APPIMAGE_URL\"" "Downloading Filen AppImage"

# Make the downloaded AppImage executable
log "Making Filen AppImage executable"
run_command "chmod +x \"$APPIMAGE_FILE\"" "Making Filen AppImage executable"

# Extract the AppImage
log "Extracting Filen AppImage"
run_command "\"$APPIMAGE_FILE\" --appimage-extract" "Extracting Filen AppImage"

# Move the extracted files to the specified directory
log "Moving extracted files to $EXTRACT_DIR"
run_command "mv -f squashfs-root \"$EXTRACT_DIR\"" "Forcing move of extracted files"

# Move the extracted directory to /opt
run_command "sudo mv -f $EXTRACT_DIR /opt/" "Forcing move of extracted files to /opt/"
# Change permissions of the directory
run_command "sudo chmod 775 /opt/filen_appimage/" "Changing permissions"
# Change ownership of the directory
run_command "sudo chown root:root /opt/filen_appimage/" "Changing ownership"
log "Filen AppImage downloaded and extracted successfully"

# Modify the Exec line in the .desktop file to point to the correct AppRun path
run_command "sudo sed -i 's|Exec=AppRun --no-sandbox %U|Exec=/opt/filen_appimage/AppRun %U|' \"$DESKTOP_FILE_PATH\"" "Modifying .desktop file"
# Move the .desktop file to the applications directory
run_command "sudo mv \"$DESKTOP_FILE_PATH\" /usr/share/applications/filen-desktop.desktop" "Moving .desktop file to /usr/share/applications/"
# Copy the icon to the icons directory
run_command "sudo cp /opt/filen_appimage/filen-desktop.png /usr/share/icons/filen-desktop.png" "Copying icon to /usr/share/icons"

# Ensure the autostart directory exists
mkdir -p "$HOME/.config/autostart"
# Copy the .desktop file to the autostart directory
run_command "sudo cp /usr/share/applications/filen-desktop.desktop $HOME/.config/autostart/filen-desktop.desktop" "Copying .desktop file to autostart"
# Create a directory for Filen in the user's home directory
run_command "mkdir -p $HOME/filen" "Creating filen directory"
# Create a desktop shortcut to the Filen directory
run_command "ln -s $HOME/filen $HOME/Desktop/Filen" "Creating desktop shortcut"
log "Filen AppImage installed successfully"

# Launch the Filen application
run_command "gio launch /usr/share/applications/filen-desktop.desktop; exec bash &" "Launching Filen"
wait $!

exit 0