#!/bin/bash

# Start logging
exec > >(tee -a "$(dirname "$0")/SSH.log") 2>&1

# Get current date and format it as a string
date=$(date +%Y%m%d)

# Add date to key --title
eval $(op ssh generate --title "$(hostname)-$date")

sshKey=$(op item get "$(hostname)-$date" --fields "label=public key")
modifiedsshKey=$(echo "$sshKey" | tr -d '\r\n"')

# Set git config settings
git config --global user.signingkey "$modifiedsshKey"
git config --global user.name 'Anders-RM'
git config --global user.email 'Anders_RMathiesen@pm.me'
git config --global gpg.format 'ssh'
#git config --global gpg.ssh.program "$HOME/.local/share/1Password/app/8/op-ssh-sign"
git config --global commit.gpgsign 'true'
git config --global url."git@github.com:".insteadOf 'https://github.com/'
git config --global core.sshCommand '/usr/bin/ssh'

# Prompt user to continue
read -n 1 -s -r -p "Press any key to continue. . ."
