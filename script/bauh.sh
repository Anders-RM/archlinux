#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/bauh.log"

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

# https://github.com/vinifmor/bauh
# Start bauh application in a new konsole terminal
run_command "konsole --noclose -e /bin/bash -c '/usr/bin/bauh; exec bash'" "Launching bauh"
wait $!

# Define configuration file paths
UI_CONFIG=$HOME/.config/bauh/config.yml
ARCH_CONFIG=$HOME/.config/bauh/arch.yml

# Modify config.yml
log "Modifying $UI_CONFIG..."
run_command "sed -i 's/after_upgrade: false/after_upgrade: true/' \"$UI_CONFIG\"" "Modifying config.yml"
run_command "sed -i 's/multithreaded: false/multithreaded: true/' \"$UI_CONFIG\"" "Modifying config.yml"
run_command "sed -i 's/auto_scale: false/auto_scale: true/' \"$UI_CONFIG\"" "Modifying config.yml"
run_command "sed -i 's/theme: light/theme: darcula/' \"$UI_CONFIG\"" "Modifying config.yml"

# Modify arch.yml
log "Modifying $ARCH_CONFIG..."
run_command "sed -i 's/aur_rebuild_detector: false/aur_rebuild_detector: true/' \"$ARCH_CONFIG\"" "Modifying arch.yml"
run_command "sed -i 's/refresh_mirrors_startup: false/refresh_mirrors_startup: true/' \"$ARCH_CONFIG\"" "Modifying arch.yml"
run_command "sed -i 's/repositories_mthread_download: false/repositories_mthread_download: true/' \"$ARCH_CONFIG\"" "Modifying arch.yml"
run_command "sed -i 's/suggest_optdep_uninstall: false/suggest_optdep_uninstall: true/' \"$ARCH_CONFIG\"" "Modifying arch.yml"
run_command "sed -i 's/suggest_unneeded_uninstall: false/suggest_unneeded_uninstall: true/' \"$ARCH_CONFIG\"" "Modifying arch.yml"
log "Configuration updates completed."

# Ensure the autostart directory exists
mkdir -p "$HOME/.config/autostart"
# Copy the bauh tray .desktop file to the autostart directory
run_command "sudo cp /usr/share/applications/bauh_tray.desktop $HOME/.config/autostart/bauh_tray.desktop" "Copying .desktop file to autostart"

exit 0