#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/kdm_sddm_Config.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# General function to run commands and handle failures
run_command() {
    if eval "$1"; then
        log "$2 succeeded"
    else
        log "$2 failed"
        exit 1
    fi
}

# Function to create or update a config file
update_config_file() {
    local file_path="$1"
    local setting="$2"
    local value="$3"
    local section="$4"

    if [ -f "$file_path" ]; then
        # Update or add the setting in the existing file
        if grep -q "^$setting=" "$file_path"; then
            sed -i "s/^$setting=.*/$setting=$value/" "$file_path"
        else
            echo -e "\n[$section]\n$setting=$value" >> "$file_path"
        fi
    else
        # Create the file and add the setting
        mkdir -p "$(dirname "$file_path")"
        echo -e "[$section]\n$setting=$value" > "$file_path"
    fi
    log "$setting updated or added in $file_path"
}

# Function to update or add a specific setting to a complex section in a config file
update_complex_section() {
    local file_path="$1"
    local section="$2"
    local setting="$3"

    if ! grep -q "\[$section\]" "$file_path"; then
        # If the section doesn't exist, add it at the end of the file
        echo -e "\n[$section]\n$setting" >> "$file_path"
    else
        # If the section exists, check if the setting exists
        if grep -q "$setting" "$file_path"; then
            # If the setting already exists, do nothing
            log "$setting already present in $section"
        else
            # Add the setting under the existing section
            sed -i "/\[$section\]/a $setting" "$file_path"
        fi
    fi
    log "$setting added or ensured in $section of $file_path"
}

# Paths and variables for configurations
SDDM_CONFIG="/etc/sddm.conf.d/kde_settings.conf"
CONFIRM_LOGOUT="$HOME/.config/ksmserverrc"
NUM_LOCK="$HOME/.config/kcminputrc"
UNPIN_CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
KRUNDER_CONFIG_FILE="$HOME/.config/krunnerrc"
DOLPON_CONFIG_FILE="$HOME/.config/dolphinrc"
SHORTCUT_CONFIG_FILE="$HOME/.config/kglobalshortcutsrc"

# Set system locale
log "Setting locale to English Denmark"
run_command "sudo localectl set-locale LANG=en_DK.UTF-8" "Locale setup"

# Create SDDM configuration
log "Creating SDDM configuration at $SDDM_CONFIG"
sudo mkdir -p "$(dirname "$SDDM_CONFIG")"
sudo tee "$SDDM_CONFIG" > /dev/null <<EOLSD
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
log "SDDM configuration created."

# Apply KDE Plasma settings
log "Applying KDE Plasma settings"
run_command "lookandfeeltool --apply org.kde.breezedark.desktop" "KDE Plasma settings"

# Update ksmserverrc for confirmLogout setting
log "Updating shutdown confirmation setting"
update_config_file "$CONFIRM_LOGOUT" "confirmLogout" "false" "General"
update_config_file "$CONFIRM_LOGOUT" "loginMode" "emptySession" "General"

# Update NumLock setting in kcminputrc
log "Updating NumLock setting"
update_config_file "$NUM_LOCK" "NumLock" "0" "Keyboard"
log "NumLock on startup set to off."

# Update or add specific settings in krunnerrc
log "Updating KRunner settings"
update_config_file "$KRUNDER_CONFIG_FILE" "FreeFloating" "true" "General"

# Update or add specific settings in dolphinrc
log "Updating Dolphin settings"
update_config_file "$DOLPON_CONFIG_FILE" "HomeUrl" "file://$HOME" "General"
update_config_file "$DOLPON_CONFIG_FILE" "RememberOpenedTabs" "false" "General"

# Unpin specific apps from the task manager
# Add the specific setting to plasma-org.kde.plasma.desktop-appletsrc
log "Unpinning apps from task manager"
update_complex_section "$UNPIN_CONFIG_FILE" "Containments][2][Applets][5][Configuration][General]" "launchers=preferred://browser"
log "Script completed successfully."

# Add trashcan to desktop
log "Adding Trash to Desktop"
sudo tee "$HOME/Desktop/Trash.desktop" > /dev/null <<EOLT
[Desktop Entry]
Name=Trash
Comment=Contains removed files
Icon=user-trash-full
EmptyIcon=user-trash
Type=Link
URL=trash:/
OnlyShowIn=KDE;
EOLT


#flameshot configuration
run_command "mkdir -p $HOME/.config/flameshot" "Creating flameshot configuration directory"
run_command "sudo tee $HOME/.config/flameshot/flameshot.ini > /dev/null <<EOLf
[General]
buttons=@Variant(\0\0\0\x7f\0\0\0\vQList<int>\0\0\0\0\a\0\0\0\x3\0\0\0\x4\0\0\0\x5\0\0\0\x12\0\0\0\xf\0\0\0\x11)
contrastOpacity=188
saveAfterCopy=false
saveAsFileExtension=png
savePathFixed=true
startupLaunch=true
EOLf" "Setting up flameshot configuration"

log "Adding shortcut"
update_complex_section "$SHORTCUT_CONFIG_FILE" "services][org.flameshot.Flameshot.desktop" "Capture=Meta+Shift+S"
update_complex_section "$SHORTCUT_CONFIG_FILE" "services][systemsettings.desktop" "_launch=Meta+I\tTools"
# Add Flameshot to autostart
log "Adding Flameshot to autostart"
run_command "sudo cp /usr/share/applications/org.flameshot.Flameshot.desktop $HOME/.config/autostart/" "Copying Flameshot to autostart"
log "Flameshot added to autostart."
exit 0
