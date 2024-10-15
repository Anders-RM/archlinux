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
)
# Install Programs using yay/aur
yayId=(
    "snapd"
    "bauh"
    "1password"
    "ttf-ms-win11-auto"
)

# Install Programs using flatpak
flatpakId=(
    "com.brave.Browser"
)

# Install Programs using snap
snapId=(
    ""
)

log "Setting locale to English Denmark"
export LC_ALL="en_DK.UTF-8"
sudo localectl set-locale LANG=en_DK.UTF-8 | tee -a "$LOG_FILE"

log "Importing 1Password GPG key"
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import | tee -a "$LOG_FILE"

# Install packages from pacman
for PId in "${pacmanId[@]}"; do
    log "Installing $PId with pacman"
    sudo pacman -S --noconfirm "$PId" | tee -a "$LOG_FILE"
done

log "Cloning yay repository"
git clone https://aur.archlinux.org/yay.git | tee -a "$LOG_FILE"
cd yay
log "Building and installing yay"
makepkg -si --noconfirm | tee -a "$LOG_FILE"
cd -
rm -rfd yay

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

#curl -fsSL https://christitus.com/linux | sh

echo "setup 1Password enable SSH agent under the developer settings."

read -p "Press any key to continue. . ."

log "Killing 1Password"
killall 1password | tee -a "$LOG_FILE"

log "Applying KDE Plasma settings"
lookandfeeltool --apply org.kde.breezedark.desktop | tee -a "$LOG_FILE"

log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"
