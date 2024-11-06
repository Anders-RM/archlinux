#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/reflector.log"

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

# Function to create or update a config file
update_config_file() {
    local file_path="$1"
    local setting="$2"
    local value="$3"

    if [ -f "$file_path" ]; then
        # If the setting already exists, update its value
        if grep -q "^$setting" "$file_path"; then
            sudo sed -i "s|^$setting .*|$setting $value|" "$file_path"
        else
            # Append the setting at the end of the file if it doesn't exist
            echo -e "\n$setting $value" | sudo tee -a "$file_path" > /dev/null
        fi
    else
        # Create the file and add the setting
        sudo mkdir -p "$(dirname "$file_path")"
        echo -e "$setting $value" | sudo tee "$file_path" > /dev/null
    fi
    echo "$setting updated or added in $file_path"
}

# Update the system package database and upgrade all packages
run_command "sudo pacman -Syyu --noconfirm" "Updating system"

# Install the reflector package
run_command "sudo pacman -S reflector --noconfirm" "Installing reflector"

# Define the paths for the reflector timer and configuration files
TIMER_CONF=/etc/systemd/system/timers.target.wants/reflector.timer
REFLECTOR_CONF="/etc/xdg/reflector/reflector.conf"

# Modify the reflector configuration file to sort by rate, select specific countries, and limit to the latest 10 mirrors
update_config_file "$REFLECTOR_CONF" "--sort" "rate"
update_config_file "$REFLECTOR_CONF" "--country" "DE,SE,DK"
update_config_file "$REFLECTOR_CONF" "--latest" "10"
log "Modified reflector configuration"

# Enable and start the reflector timer and service
run_command "sudo systemctl enable --now reflector.timer" "Enabling and starting reflector timer"
run_command "sudo systemctl enable --now reflector.service" "Enabling and starting reflector service"

# Modify the reflector.timer configuration to run daily at 18:00
run_command "sudo sed -i 's/^OnCalendar=weekly/OnCalendar=\*-*-* 18:00:00/' \"$TIMER_CONF\"" "Modified reflector.timer configuration"

# Reload the systemd daemon to apply changes
run_command "sudo systemctl daemon-reload" "Reloading systemd daemon"

# Restart the reflector timer to apply the new schedule
run_command "sudo systemctl restart reflector.timer" "Restarting reflector timer"

exit 0