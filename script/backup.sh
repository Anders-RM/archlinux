#!/bin/bash
sudo tee "/usr/local/bin/BackupScript.sh" > /dev/null <<EOLB
#!/bin/bash

# Specify source and destination directories
source="$HOME/filen/*"
destinationBase="//192.168.3.2/Anders"

# Get the current date and time in the desired format, but replace forbidden characters
date=$(date +"%d_%m_%Y - %H_%M")

# Combine the base destination path with the formatted date
destination="$destinationBase/$date"

# Specify the log file path
logFile="$destination/Backup.log"

# Create the destination directory if it does not exist
if [ ! -d "$destination" ]; then
    mkdir -p "$destination"
fi

# If the log file exists, delete it
if [ -f "$logFile" ]; then
    rm "$logFile"
fi

# Start logging
exec > >(tee -i "$logFile")
exec 2>&1

# Define the credentials (replace with actual username and password)
username="YourUsername"
password="YourPassword"

# Use the credential to access the destination path
if ! mount -t cifs "$destinationBase" /mnt/backup -o username="$username",password="$password"; then
    echo "Failed to mount $destinationBase"
    exit 1
fi

# Create the destination directory if it does not exist on the mounted drive
if [ ! -d "/mnt/backup/$date" ]; then
    mkdir -p "/mnt/backup/$date"
fi

# Copy the files and directories
cp -r "$source" "/mnt/backup/$date"

# Unmount the drive after copying
umount /mnt/backup

# Stop logging
exec > /dev/tty 2>&1
EOLB

# Ensure BackupScript.sh has executable permissions
chmod +x /usr/local/bin/BackupScript.sh

# Schedule BackupScript.sh to run once a week using cron
(crontab -l 2>/dev/null; echo "0 20 * * 0 /usr/local/bin/BackupScript.sh") | crontab -

# Description: Backup proton drive to NAS
# Note: Ensure BackupScript.sh has executable permissions: chmod +x /usr/local/bin/BackupScript.sh
