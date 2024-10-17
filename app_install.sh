#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/App_install.log"

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
echo "Setup 1Password: Enable SSH agent under the developer settings.
"
read -p "Press any key to continue. . ."

log "Killing 1Password"
killall 1password | tee -a "$LOG_FILE"

exit 0
