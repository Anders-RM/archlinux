#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/package_install.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Install Programs using pacman
pacmanId=(
    "vlc"
    "zed"
    "flatpak"
    "python-beautifulsoup4"
    "python-lxml"
)

# Repositories to clone and install
cloneRepos=(
    "https://aur.archlinux.org/yay.git"
)

repoDirs=(
    "yay"
)

# Install Programs using yay/aur
yayId=(
    "snapd"
    "bauh"
    "1password"
)

# Install Programs using flatpak
flatpakId=(
    "com.brave.Browser"
)

# Install Programs using snap
snapId=(
    ""
)

# Set system locale
log "Setting locale to English Denmark"
export LC_ALL="en_DK.UTF-8"
sudo localectl set-locale LANG=en_DK.UTF-8 | tee -a "$LOG_FILE"

# Import 1Password GPG key
log "Importing 1Password GPG key"
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import | tee -a "$LOG_FILE"

# Update pacman packages
log "Starting pacman update..."
sudo pacman -Syu --noconfirm | tee -a "$LOG_FILE"
log "Pacman update completed."

# Install packages from pacman
for PId in "${pacmanId[@]}"; do
    log "Installing $PId with pacman"
    sudo pacman -S --noconfirm "$PId" | tee -a "$LOG_FILE"
done

# Clone and install repositories
for i in "${!cloneRepos[@]}"; do
    repoUrl="${cloneRepos[$i]}"
    repoDir="${repoDirs[$i]}"
    
    log "Cloning $repoDir repository"
    git clone "$repoUrl" | tee -a "$LOG_FILE"
    
    cd "$repoDir" || exit
    log "Building and installing $repoDir"
    makepkg -si --noconfirm | tee -a "$LOG_FILE"
    
    cd - || exit
    rm -rf "$repoDir"
done

# Install packages for yay
for YId in "${yayId[@]}"; do
    log "Installing $YId with yay"
    yay -Syu --noconfirm "$YId" | tee -a "$LOG_FILE"
    log "Sleeping for 10 seconds"
    sleep 10
done

# Enable and configure Snap
log "Enabling Snap"
sudo systemctl enable --now snapd.socket
sudo systemctl enable --now snapd.apparmor.service
log "Linking snapd"
sudo ln -s /var/lib/snapd/snap /snap | tee -a "$LOG_FILE"

# Install packages for flatpak
for FId in "${flatpakId[@]}"; do
    log "Installing $FId with flatpak"
    flatpak install flathub -y "$FId" | tee -a "$LOG_FILE"
done

# Install packages from snap
for SId in "${snapId[@]}"; do
    if [ -n "$SId" ]; then
        log "Installing $SId with snap"
        sudo snap install --stable --classic "$SId" | tee -a "$LOG_FILE"
    fi
done

# Final setup for 1Password
log "Setup 1Password: Enable SSH agent under the developer settings."
read -p "Press any key to continue. . ."

log "Killing 1Password"
killall 1password | tee -a "$LOG_FILE"

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
    if grep -q '^ConfirmLogout=' "$CONFIG_FILE"; then
        # If it exists, change its value to false
        sed -i 's/^ConfirmLogout=.*/ConfirmLogout=false/' "$CONFIG_FILE"
    else
        # If it doesn't exist, add it to the file
        echo "ConfirmLogout=false" >> "$CONFIG_FILE"
    fi
    log "Shutdown confirmation disabled."
else
    log "Configuration file not found. Creating it..."
    # Create the config file and set ConfirmLogout to false
    mkdir -p "$HOME/.config"
    echo "[General]" > "$CONFIG_FILE"
    echo "ConfirmLogout=false" >> "$CONFIG_FILE"
    log "Configuration file created and shutdown confirmation disabled."
fi

# Create the update script
sudo tee "/usr/local/bin/update_script.sh" > /dev/null <<EOLU
#!/bin/bash

LOGFILE="/var/log/update_script.log"

# Ensure the log file exists
touch \$LOGFILE

# Log function
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" | tee -a \$LOGFILE
}

# Update pacman packages
log "Starting pacman update..."
sudo pacman -Syu --noconfirm | tee -a \$LOGFILE
log "Pacman update completed."

# Update AUR packages
log "Starting yay update..."
yay -Syu --noconfirm | tee -a \$LOGFILE
log "Yay update completed."

# Update Flatpak packages
log "Starting Flatpak update..."
flatpak update -y | tee -a \$LOGFILE
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
sudo snap refresh | tee -a \$LOGFILE
log "Snap update completed."

log "All updates completed successfully."
exit 0
EOLU

log "Configuration file created at update_script.sh"
sudo chmod +x /usr/local/bin/update_script.sh

# Create systemd service for the update script
sudo tee "/etc/systemd/system/update-script.service" > /dev/null <<EOLS
[Unit]
Description=Run update script on shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update_script.sh
RemainAfterExit=yes
TimeoutStopSec=1800

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOLS

log "Configuration file created at update-script.service"

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable update-script.service

# Final updates and reboot
log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"