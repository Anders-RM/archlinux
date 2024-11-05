#!/bin/bash

# arguments
 # Function to display help message
 show_help() {
    echo "Usage: ./start.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo "  -v, --novm        Skip VM-related scripts"
    echo "  -g, --nogaming    Skip gaming-related scripts"
    # Add more options here as needed
 }

 # Check for help argument
 for arg in "$@"; do
    case $arg in
        -h|--help)
            show_help
            exit 0
            ;;
    esac
 done

 # Default value for arguments
 EXECUTE_VM=true
 EXECUTE_GAMING=true

 # Parse command-line arguments
 while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--novm) EXECUTE_VM=false ;;  # Disable VM-related scripts
        -g|--nogaming) EXECUTE_GAMING=false ;;  # Disable gaming-related scripts
        -h|--help) show_help; exit 0 ;;  # Show help message and exit
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

# List of scripts to execute
scripts=(
    "app_install.sh"
    "kdm_sddm_Config.sh"
    "appimage.sh"
    "bauh.sh"
    "reflector.sh"
    "update_service.sh"
)

# Conditionally add vm.sh to the list of scripts
if [ "$EXECUTE_VM" = true ]; then
    scripts+=("vm.sh")
fi

# Conditionally add gaming.sh to the list of scripts
if [ "$EXECUTE_GAMING" = true ]; then
    scripts+=("gaming.sh")
fi

# Execute each script in the list
for script in "${scripts[@]}"; do
    execute_and_log "$script"
done

# Final updates and reboot
log "Rebooting system"
sudo reboot | tee -a "$LOG_FILE"