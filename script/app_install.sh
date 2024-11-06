#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"  # Get the directory where the script is located
LOG_FILE="$SCRIPT_DIR/App_install.log"      # Set the log file path in the script directory

# Ensure the log file exists by creating the necessary directories and the log file
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function to output messages with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# General function to run commands and log their success or failure
run_command() {
    if eval "$1"; then
        log "$2 succeeded"   # Log success if the command executes successfully
    else
        log "$2 failed"      # Log failure and exit if the command fails
        exit 1
    fi
}

# Define package lists
pacmanId=("vlc" "flatpak" "python-beautifulsoup4" "python-lxml" "fuse2" "axel" "aria2" "kio-admin" "fastfetch" "jq")  # Packages for pacman
cloneRepos=("https://aur.archlinux.org/yay.git")       # Repositories to clone (for example, yay AUR helper)
repoDirs=("yay")                                       # Directories corresponding to each repository
yayId=("snapd" "bauh" "1password" "visual-studio-code-bin" "brave-bin" "filen-desktop-git") # Packages for yay (AUR packages)
flatpakId=()                                           # Packages for flatpak (empty here but ready for addition)
snapId=()                                              # Packages for snap (empty here but ready for addition)

# Import the GPG key for 1Password for secure package installation
log "Importing 1Password GPG key"
run_command "curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import" "Importing 1Password GPG key"

# Update pacman packages to the latest versions
log "Starting pacman update..."
run_command "sudo pacman -Syu --noconfirm" "Pacman update"

# Install predefined packages using pacman
if [ ${#pacmanId[@]} -gt 0 ]; then
    log "Installing packages with pacman"
    run_command "sudo pacman -S --noconfirm ${pacmanId[*]}" "Pacman package installation"
fi

# Clone and install software from AUR repositories
for i in "${!cloneRepos[@]}"; do
    repoUrl="${cloneRepos[$i]}"
    repoDir="${repoDirs[$i]}"
    
    log "Cloning $repoDir repository"
    run_command "git clone \"$repoUrl\" \"$repoDir\"" "Cloning $repoDir"
    
    # Navigate into the cloned directory, build, and install
    pushd "$repoDir" > /dev/null || exit
    log "Building and installing $repoDir"
    run_command "makepkg -si --noconfirm" "Building and installing $repoDir"
    
    # Return to the previous directory and clean up
    popd > /dev/null || exit
    rm -rf "$repoDir"
done

# Install packages using yay (AUR helper)
if [ ${#yayId[@]} -gt 0 ]; then
    log "Installing packages with yay"
    run_command "yay -Syu --noconfirm ${yayId[*]}" "$yayId installation"
fi

# Enable and configure Snap package manager
log "Enabling Snap"
run_command "sudo systemctl enable --now snapd.socket && sudo systemctl enable --now snapd.apparmor.service" "Enabling snap services"
run_command "sudo ln -sf /var/lib/snapd/snap /snap" "Linking snapd"

# Install packages using flatpak (if any are specified)
if [ ${#flatpakId[@]} -gt 0 ]; then
    log "Installing packages with flatpak"
    run_command "flatpak install flathub -y ${flatpakId[*]}" "$flatpakId package installation"
fi

# Install specified packages from snap (if any are specified)
for SId in "${snapId[@]}"; do
    if [ -n "$SId" ]; then
        log "Installing $SId with snap"
        run_command "sudo snap install --stable --classic \"$SId\"" "Snap package installation for $SId"
    fi
done

# Set up autostart if not already configured
mkdir -p "$Home_Dir/.config/autostart"
run_command "cp /usr/share/applications/filen-desktop.desktop $Home/.config/autostart/filen-desktop.desktop" "Copying .desktop file to autostart"

# Ensure user directory exists and create shortcut
run_command "mkdir -p \"$Home/filen\"" "Creating filen directory"
run_command "ln -sf \"$Home/filen\" \"$Home/Desktop/Filen\"" "Creating desktop shortcut"

run_command "gio launch /usr/share/applications/filen-desktop.desktop" "Launching Filen"

# Final setup for 1Password (user guidance for SSH agent setup)
echo "Setup 1Password: Enable SSH agent under the developer settings."
#run_command "konsole --noclose -e bash -c 'gio launch /usr/share/applications/1password.desktop; exec bash'" "Launching 1password"
run_command "gio launch /usr/share/applications/1password.desktop" "Launching Filen"

wait $!

# Exit script
exit 0
