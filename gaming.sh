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

run_command "sudo pacman -Syyu --noconfirm" "Updating system"
run_command "sudo pacman -S lutris steam --noconfirm" "Installing gaming packages"
# Open URLs in the default web browser and wait for the browser to close
urls=(
    "https://lutris.net/games/ea-app/"
    "https://lutris.net/games/epic-games-store/"
    "https://lutris.net/games/gog-galaxy/"
    "https://lutris.net/games/ubisoft-connect/"
    "https://lutris.net/games/rockstar-games-launcher/"
)

for url in "${urls[@]}"; then
    xdg-open "$url"
    log "Opened $url in the browser"
    read -p "Press [Enter] after closing the browser window for $url"
done
exit 0