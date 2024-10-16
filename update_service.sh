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

# Create the update script
sudo tee "/usr/local/bin/update_script.sh" > /dev/null <<EOLU
#!/bin/bash

LOGFILE="/var/log/update_script.log"

# Ensure the log file exists
touch \$LOGFILE

# Log function
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" | tee -a \$LOGFILE
}

# Update pacman packages
log "Starting pacman update..."
sudo pacman -Syu --noconfirm | tee -a \$LOGFILE
log "Pacman update completed."

# Update AUR packages
log "Starting yay update..."
yay -Syu --noconfirm | tee -a \$LOGFILE
log "Yay update completed."

# Update Flatpak packages
log "Starting Flatpak update..."
flatpak update -y | tee -a \$LOGFILE
log "Flatpak update completed."

# Update Snap packages
log "Starting Snap update..."
sudo snap refresh | tee -a \$LOGFILE
log "Snap update completed."
ks
log "All updates completed successfully."
exit 0
EOLU

log "Configuration file created at update_script.sh"
sudo chmod +x /usr/local/bin/update_script.sh

# Create systemd service for the update script
sudo tee "/etc/systemd/system/update-script.service" > /dev/null <<EOLS
[Unit]
Description=Run update script on shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update_script.sh
RemainAfterExit=yes
TimeoutStopSec=1800

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOLS

log "Configuration file created at update-script.service"

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable update-script.service