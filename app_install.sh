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

# General function to run commands and log output
run_command() {
    if eval "$1"; then
        log "$2 succeeded"
    else
        log "$2 failed"
        exit 1
    fi
}

# Define packages
pacmanId=("vlc" "flatpak" "python-beautifulsoup4" "python-lxml" "fuse2" "axel" "aria2" "kio-admin")
cloneRepos=("https://aur.archlinux.org/yay.git")
repoDirs=("yay")
yayId=("snapd" "bauh" "1password""brave-bin")
flatpakId=()
snapId=()

# Import 1Password GPG key
log "Importing 1Password GPG key"
run_command "curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import" "Importing 1Password GPG key"

# Update pacman packages
log "Starting pacman update..."
run_command "sudo pacman -Syu --noconfirm" "Pacman update"

# Install packages from pacman
if [ ${#pacmanId[@]} -gt 0 ]; then
    log "Installing packages with pacman"
    run_command "sudo pacman -S --noconfirm ${pacmanId[*]}" "Pacman package installation"
fi

# Clone and install repositories
for i in "${!cloneRepos[@]}"; do
    repoUrl="${cloneRepos[$i]}"
    repoDir="${repoDirs[$i]}"
    
    log "Cloning $repoDir repository"
    run_command "git clone \"$repoUrl\" \"$repoDir\"" "Cloning $repoDir"
    
    pushd "$repoDir" > /dev/null || exit
    log "Building and installing $repoDir"
    run_command "makepkg -si --noconfirm" "Building and installing $repoDir"
    
    popd > /dev/null || exit
    rm -rf "$repoDir"
done

# Install packages for yay
if [ ${#yayId[@]} -gt 0 ]; then
    log "Installing packages with yay"
    run_command "yay -Syu --noconfirm ${yayId[*]}" "Yay package installation"
fi

# Enable and configure Snap
log "Enabling Snap"
run_command "sudo systemctl enable --now snapd.socket && sudo systemctl enable --now snapd.apparmor.service" "Enabling snap services"
run_command "sudo ln -sf /var/lib/snapd/snap /snap" "Linking snapd"

# Install packages for flatpak
if [ ${#flatpakId[@]} -gt 0 ]; then
    log "Installing packages with flatpak"
    run_command "flatpak install flathub -y ${flatpakId[*]}" "Flatpak package installation"
fi

# Install packages from snap
for SId in "${snapId[@]}"; do
    if [ -n "$SId" ]; then
        log "Installing $SId with snap"
        run_command "sudo snap install --stable --classic \"$SId\"" "Snap package installation for $SId"
    fi
done

# Final setup for 1Password
echo "Setup 1Password: Enable SSH agent under the developer settings."
read -p "Press any key to continue. . ."

log "Killing 1Password"
run_command "killall 1password" "Killing 1Password"

exit 0