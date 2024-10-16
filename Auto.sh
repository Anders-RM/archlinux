#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/package_install.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

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
    "p7zip"
    "httpdirfs"
    "meson"
    "help2man"
    "doxygen"
    "graphviz"
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

# Repositories to clone and install
cloneRepos=(
    "https://aur.archlinux.org/yay.git"
    "https://aur.archlinux.org/httpdirfs.git"
    "https://aur.archlinux.org/ttf-ms-win11-auto.git"
)

repoDirs=(
    "yay"
    "httpdirfs"
    "ttf-ms-win11-auto"
)

sddmir="/etc/sddm.conf.d"
sddmFile="$sddmir/kde_settings.conf"

log "Setting locale to English Denmark"
export LC_ALL="en_DK.UTF-8"
sudo localectl set-locale LANG=en_DK.UTF-8 | tee -a "$LOG_FILE"

log "Importing 1Password GPG key"
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import | tee -a "$LOG_FILE"

# Update pacman packages
log "Starting pacman update..."
sudo pacman -Syu --noconfirm | tee -a $LOGFILE
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
    
    cd "$repoDir"
    log "Building and installing $repoDir"
    makepkg -si --noconfirm | tee -a "$LOG_FILE"
    
    cd -
    rm -rfd "$repoDir"
done

# Install packages for yay
for YId in "${yayId[@]}"; do
    log "Installing $YId with yay"
    yay -Syu --noconfirm "$YId" | tee -a "$LOG_FILE"
    log "Sleeping for 10 seconds"
    sleep 10
done

log "Enable Snap"
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

echo "setup 1Password enable SSH agent under the developer settings."

read -p "Press any key to continue. . ."

log "Killing 1Password"
killall 1password | tee -a "$LOG_FILE"

# Create the directory if it doesn't exist
sudo mkdir -p "$sddmir"

sudo tee "$sddmFile" > /dev/null <<EOL
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
EOL

# Display a message
echo "Configuration file created at $sddmFile"

log "Applying KDE Plasma settings"
lookandfeeltool --apply org.kde.breezedark.desktop | tee -a "$LOG_FILE"

# Update pacman packages
log "Starting pacman update..."
sudo pacman -Syu --noconfirm | tee -a $LOGFILE
log "Pacman update completed."

# Update AUR packages
log "Starting yay update..."
yay -Syu --noconfirm | tee -a $LOGFILE
log "Yay update completed."

# Update Flatpak packages
log "Starting Flatpak update..."
flatpak update -y | tee -a $LOGFILE
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
sudo snap refresh | tee -a $LOGFILE
log "Snap update completed."


log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"
