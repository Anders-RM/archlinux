#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"  # Get the directory of the script
LOG_FILE="$SCRIPT_DIR/zsh.log"         # Define the log file path

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"  # Create the directory for the log file if it doesn't exist
touch "$LOG_FILE"                  # Create the log file if it doesn't exist

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"  # Log the message with a timestamp
}

# General function to run commands and log output
run_command() {
    if eval "$1"; then
        log "$2 succeeded"  # Log success message if the command succeeds
    else
        log "$2 failed"     # Log failure message if the command fails
        exit 1              # Exit the script with an error code
    fi
}

run_command "sudo pacman -Sy zsh --noconfirm" "Installing zsh"
run_command "chsh -s $(which zsh)" "Changing default shell to zsh"
run_command "sh -c \"$(wget -O- https://install.ohmyz.sh)\"" "Installing oh-my-zsh"

exit 0  # Exit the script successfully