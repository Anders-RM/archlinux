#!/bin/bash

# arguments
# Function to display help message
show_help() {
    echo "Usage: ./start.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo "  -v, --novm    Skip VM-related scripts"
    echo "  -z, --nozsh     Skip ZSH installation"
    # Add more options here as needed
}

# Default value for arguments
EXECUTE_VM=true
EXECUTE_ZSH=true

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--novm) EXECUTE_VM=false ;;  # Disable VM-related scripts
        -z|--nozsh) EXECUTE_ZSH=false ;;  # Disable ZSH installation
        -h|--help) show_help; exit 0 ;;  # Show help message and exit
        -*)
            if [[ $1 =~ v ]]; then EXECUTE_VM=false; fi
            ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;  # Handle unknown parameters
    esac
    shift
done

 # Define the script directory and log file
 SCRIPT_DIR="$(dirname "$(realpath "$0")")"
 LOG_FILE="$SCRIPT_DIR/start.log"

 # Ensure the log file exists
 mkdir -p "$(dirname "$LOG_FILE")"
 touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Execute scripts and log their output
execute_and_log() {
    local script="$1"
    log "Executing $script"
    
    # Execute the script in a subshell and capture its exit code
    (
        ./script/"$script"
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

# List of scripts to execute
scripts=(
    "app_install.sh"
    "kdm_sddm_Config.sh"
    "update_service.sh"
    "bauh.sh"
    "reflector.sh"
)

# Conditionally add vm.sh to the list of scripts
if [ "$EXECUTE_VM" = true ]; then
    scripts+=("vm.sh")
fi

if [ "$EXECUTE_ZSH" = true ]; then
    scripts+=("zsh.sh")
fi
chmod +x -R script
log "Changing permissions of scripts"

# Execute each script in the list
for script in "${scripts[@]}"; do
    execute_and_log "$script"
done

#read -p "Press enter to reboot"
# Final updates and reboot
log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"