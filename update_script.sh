#!/bin/bash
# Define the script directory and log file
LOG_DIR="/var/log/filen"
LOG_FILE="$LOG_DIR/update_script.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"

TEMP_DIR=~/.temp
APPIMAGE_LOCATION="$TEMP_DIR/appimage"
APPIMAGE_URL="https://cdn.filen.io/desktop/release/filen_x86_64.AppImage"
APPIMAGE_FILE="$APPIMAGE_LOCATION/filen_x86_64.AppImage"
EXTRACT_DIR="$APPIMAGE_LOCATION/filen_appimage"
INSTALL_DIR="/opt/filen_appimage"
DESKTOP_FILE_PATH="$INSTALL_DIR/filen-desktop.desktop"
PACKAGE_JSON_PATH="$INSTALL_DIR/resources/app/package.json"

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

echo "$(date '+%Y-%m-%d %H:%M:%S') - Creating temporary directory for AppImage" | tee -a "$LOG_FILE"
mkdir -p "$APPIMAGE_LOCATION"

# Download latest version to a temporary file to compare versions
TEMP_APPIMAGE="$APPIMAGE_LOCATION/temp_filen_x86_64.AppImage"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking for updates..." | tee -a "$LOG_FILE"
curl -L -o "$TEMP_APPIMAGE" "$APPIMAGE_URL" --silent --show-error

if [ -f "$PACKAGE_JSON_PATH" ]; then
    CURRENT_VERSION=$(jq -r '.version' "$PACKAGE_JSON_PATH")
    TEMP_VERSION=$(./"$TEMP_APPIMAGE" --appimage-extract jq -r '.version' squashfs-root/resources/app/package.json)

    if [ "$CURRENT_VERSION" == "$TEMP_VERSION" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - No update available. The AppImage is already up-to-date." | tee -a "$LOG_FILE"
        rm "$TEMP_APPIMAGE"
        exit 0
    else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Update found. Proceeding with update..." | tee -a "$LOG_FILE"
        mv "$TEMP_APPIMAGE" "$APPIMAGE_FILE"
    fi
else
echo "$(date '+%Y-%m-%d %H:%M:%S') - AppImage not found. Downloading new version." | tee -a "$LOG_FILE"
    mv "$TEMP_APPIMAGE" "$APPIMAGE_FILE"
fi

# Make the downloaded AppImage executable
echo "$(date '+%Y-%m-%d %H:%M:%S') - Making Filen AppImage executable" | tee -a "$LOG_FILE"
chmod +x "$APPIMAGE_FILE"

# Remove old installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Removing old installation at $INSTALL_DIR" | tee -a "$LOG_FILE"
    sudo rm -rf "$INSTALL_DIR"
fi

# Extract the new AppImage
echo "$(date '+%Y-%m-%d %H:%M:%S') - Extracting Filen AppImage" | tee -a "$LOG_FILE"
"$APPIMAGE_FILE" --appimage-extract

# Move the extracted files to /opt
echo "$(date '+%Y-%m-%d %H:%M:%S') - Moving extracted files to $INSTALL_DIR" | tee -a "$LOG_FILE"
sudo mv squashfs-root "$INSTALL_DIR"
sudo chmod 775 "$INSTALL_DIR"
sudo chown root:root "$INSTALL_DIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Filen AppImage downloaded and extracted successfully" | tee -a "$LOG_FILE"

# Update the .desktop file for the correct path and move to applications directory
echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating .desktop file" | tee -a "$LOG_FILE"
sudo sed -i 's|Exec=AppRun --no-sandbox %U|Exec=$INSTALL_DIR/AppRun %U|' "$INSTALL_DIR/filen-desktop.desktop"
sudo mv "$INSTALL_DIR/filen-desktop.desktop" /usr/share/applications/filen-desktop.desktop
sudo cp "$INSTALL_DIR/filen-desktop.png" /usr/share/icons/filen-desktop.png

# Set up autostart if not already configured
mkdir -p "$HOME/.config/autostart"
cp /usr/share/applications/filen-desktop.desktop "$HOME/.config/autostart/filen-desktop.desktop"

# Ensure user directory exists and create shortcut
mkdir -p "$HOME/filen"
ln -sf "$HOME/filen" "$HOME/Desktop/Filen"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Filen AppImage updated and installed successfully" | tee -a "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Removing temporary directory" | tee -a "$LOG_FILE"
rm -rf "$APPIMAGE_LOCATION"

# log completion of all updates
echo "$(date '+%Y-%m-%d %H:%M:%S') - All updates completed successfully." | tee -a "$LOG_FILE"

exit 0