#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="/usr/local/bin/update"
LOG_FILE="$SCRIPT_DIR/run_updates.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Run update_script.sh
log "Running update_script.sh"
"$SCRIPT_DIR/update_script.sh"
if [ $? -ne 0 ]; then
    log "update_script.sh failed"
    exit 1
fi

# Run appimage.sh
log "Running appimage.sh"
"$SCRIPT_DIR/appimage.sh"
if [ $? -ne 0 ]; then
    log "appimage.sh failed"
    exit 1
fi

log "Both scripts completed successfully"
exit 0