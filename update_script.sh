#!/bin/bash

LOGFILE="/var/log/update_script.log"

# Ensure the log file exists
touch "$LOGFILE"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
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

execute_and_log() {
    local script="$1"
    log "Executing $script"
    
    # Execute the script in a subshell and capture its exit code
    (
        ./"$script"
    ) | tee -a "$LOG_FILE"
    local exit_code=${PIPESTATUS[0]}
    
    # Check if the exit code is non-zero
    if [ $exit_code -ne 0 ]; then
        log "Error executing $script (exit code: $exit_code)"
        exit $exit_code
    else
        log "$script executed successfully"
    fi
}

scripts=(
    "appimage.sh"
)


# Update pacman packages
log "Starting pacman update..."
run_command "sudo pacman -Syyu --noconfirm" "Pacman update"
log "Pacman update completed."

# Update AUR packages
log "Starting yay update..."
run_command "yay -Syyu --noconfirm" "Yay update"
log "Yay update completed."

# Update Flatpak packages
log "Starting Flatpak update..."
flatpak update -y 
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
run_command "sudo snap refresh" "Snap update"
log "Snap update completed."

# Log completion of all updates
log "All updates completed successfully."

for script in "${scripts[@]}"; do
    execute_and_log "$script"
done

exit 0