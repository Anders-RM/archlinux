#!/bin/bash

# Define the script directory and log file
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/vm.log"

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

# Check if the CPU supports virtualization
log "Checking if virtualization is enabled"
if [ "$(grep -Ec '(vmx|svm)' /proc/cpuinfo)" -gt 0 ]; then
    log "Virtualization Enabled"
    run_command "sudo pacman -Syyu --noconfirm" "Updating system"
    run_command "sudo pacman -S qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs ebtables vde2 openbsd-netcat" "Installing VM packages"
    run_command "sudo systemctl enable libvirtd.service" "Enabling libvirtd service"
    run_command "sudo systemctl start libvirtd.service" "Starting libvirtd service"
    run_command "sudo sed -i '/^#.*unix_sock_group = \"libvirt\"/s/^#//' /etc/libvirt/libvirtd.conf" "Setting libvirt group"
    run_command "sudo sed -i '/^#.*unix_sock_rw_perms = \"0770\"/s/^#//' /etc/libvirt/libvirtd.conf" "Setting libvirt permissions"
    run_command "sudo usermod -aG libvirt $USER" "Adding user to libvirt group"
    run_command "sudo systemctl restart libvirtd.service" "Restarting libvirtd service"
else
    log "Virtualization Disabled"
    read -p "Virtualization is disabled. Do you want to continue with the installation? (y/n): " choice
    case "$choice" in 
        y|Y ) 
            log "Continuing with installation"
            run_command "sudo pacman -Syyu --noconfirm" "Updating system"
            run_command "sudo pacman -S qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs ebtables vde2 openbsd-netcat" "Installing VM packages"
            run_command "sudo systemctl enable libvirtd.service" "Enabling libvirtd service"
            run_command "sudo systemctl start libvirtd.service" "Starting libvirtd service"
            run_command "sudo sed -i '/^#.*unix_sock_group = \"libvirt\"/s/^#//' /etc/libvirt/libvirtd.conf" "Setting libvirt group"
            run_command "sudo sed -i '/^#.*unix_sock_rw_perms = \"0770\"/s/^#//' /etc/libvirt/libvirtd.conf" "Setting libvirt permissions"
            run_command "sudo usermod -aG libvirt $USER" "Adding user to libvirt group"
            run_command "sudo systemctl restart libvirtd.service" "Restarting libvirtd service"
            ;;
        n|N ) 
            log "Installation aborted by user"
            exit 1
            ;;
        * ) 
            log "Invalid choice. Installation aborted."
            exit 1
            ;;
    esac
fi


exit 0