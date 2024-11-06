#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/gaming.log"

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

# Update the system package database and upgrade all packages
run_command "sudo pacman -Syyu --noconfirm" "Updating system"

# Install Lutris and Steam gaming packages
run_command "sudo pacman -S lutris steam extra/python-setuptools --noconfirm" "Installing gaming packages"
#run_command "yay -S --noconfirm protonup-qt" "Installing ProtonUp"

# Define an array of URLs to open in the default web browser
urls=(
    "https://lutris.net/games/ea-app/"
    "https://lutris.net/games/epic-games-store/"
    "https://lutris.net/games/gog-galaxy/"
    "https://lutris.net/games/ubisoft-connect/"
    "https://lutris.net/games/rockstar-games-launcher/"
)

# Loop through each URL, open it in the default web browser, and log the action
for url in "${urls[@]}"; do
    xdg-open "$url"
    log "Opened $url in the browser"
done

# Prompt the user to press Enter after closing all browser windows
read -p "Press [Enter] after closing all browser windows"

# Exit the script successfully
exit 0