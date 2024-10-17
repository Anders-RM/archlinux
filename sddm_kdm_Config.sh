#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/sddm_kdm_Config.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Set system locale
log "Setting locale to English Denmark"
export LC_ALL="en_DK.UTF-8"
sudo localectl set-locale LANG=en_DK.UTF-8 | tee -a "$LOG_FILE"

# Create SDDM configuration
sudo mkdir -p "/etc/sddm.conf.d"

sudo tee "/etc/sddm.conf.d/kde_settings.conf" > /dev/null <<EOLSD
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze

[Users]
MaximumUid=60513
MinimumUid=1000
EOLSD

# Display message for configuration file creation
log "Configuration file created at kde_settings.conf"

# Apply KDE Plasma settings
log "Applying KDE Plasma settings"
lookandfeeltool --apply org.kde.breezedark.desktop | tee -a "$LOG_FILE"


# Path to the ksmserverrc configuration file
CONFIG_FILE="$HOME/.config/ksmserverrc"

# Check if the file exists
if [ -f "$CONFIG_FILE" ]; then
    # Update or add the ConfirmLogout setting
    if grep -q '^confirmLogout=' "$CONFIG_FILE"; then
        # If it exists, change its value to false
        sed -i 's/^confirmLogout=.*/confirmLogout=false/' "$CONFIG_FILE"
    else
        # If it doesn't exist, add it to the file
        echo "confirmLogout=false" >> "$CONFIG_FILE"
    fi
    log "Shutdown confirmation disabled."
else
    log "Configuration file not found. Creating it..."
    # Create the config file and set ConfirmLogout to false
    mkdir -p "$HOME/.config"
    echo "[General]" > "$CONFIG_FILE"
    echo "confirmLogout=false" >> "$CONFIG_FILE"
    log "Configuration file created and shutdown confirmation disabled."
fi

# Define the KDE config file location
KDE_CONFIG_FILE="$HOME/.config/kcminputrc"

# Check if the config file exists; if not, create it
if [[ ! -f "$KDE_CONFIG_FILE" ]]; then
    echo "[Keyboard]" > "$KDE_CONFIG_FILE"
fi

# Add or update the NumLock setting
if grep -q "NumLock" "$KDE_CONFIG_FILE"; then
    sed -i 's/NumLock=.*/NumLock=0/' "$KDE_CONFIG_FILE"
else
    echo -e "\n[Keyboard]\nNumLock=0" >> "$KDE_CONFIG_FILE"
fi

exit 0