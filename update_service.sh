#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/update_service.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}
run_command() {
    if eval "$1"; then
        log "$2 succeeded"
    else
        log "$2 failed"
        exit 1
    fi
}

UPDATE_FOLDER="/usr/local/bin/update"
run_command "sudo mkdir -p \"$UPDATE_FOLDER\"" "Creating update directory"

run_command "sudo cp \"$SCRIPT_DIR\"/update_script.sh \"$UPDATE_FOLDER\"/update_script.sh" "Moving update script to /usr/local/bin"

run_command "sudo chmod +x \"$UPDATE_FOLDER\"/update_script.sh" "Making update script executable"

# Create systemd service for the update script
sudo tee "/etc/systemd/system/update-script.service" > /dev/null <<EOLS
[Unit]
Description=Update Script
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=$UPDATE_FOLDER/update_script.sh
RemainAfterExit=yes
TimeoutStopSec=1800

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOLS

# Log the creation of the systemd service
log "Configuration file created at update-script.service"

# Reload systemd to apply the new service and enable it
run_command "sudo systemctl daemon-reload" "Reloading systemd"
run_command "sudo systemctl enable update-script.service" "Enabling update-script service"

exit 0