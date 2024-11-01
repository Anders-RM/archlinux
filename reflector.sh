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


run_command "sudo pacman -Syyu --noconfirm" "Updating system"
run_command "sudo pacman -S reflector --noconfirm" "Installing reflector"

# Modify the reflector configuration file
REFLECTOR_CONF="/etc/xdg/reflector/reflector.conf"
update_config_file "$REFLECTOR_CONF" "--sort" "rate"
#update_config_file "$REFLECTOR_CONF" "# --country" "--country DE,SE,DK"
sudo sed -i 's/^# --country.*$/  --country DE,SE,DK/' "$REFLECTOR_CONF"
update_config_file "$REFLECTOR_CONF" "--latest" "10"

log "Modified reflector configuration"

run_command "sudo systemctl enable --now reflector.timer" "Enabling and starting reflector timer"
run_command "sudo systemctl enable --now reflector.service" "Enabling and starting reflector service"

exit 0