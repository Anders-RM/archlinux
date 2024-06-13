#!/bin/bash

# Install Programs using pacman
pacmanId=(
    "git"
    "glib2-devel"
    "vlc"
)

yayId=(
    "pamac-all"
    "1password"
    "1password-cli"
    "ttf-ms-win11-auto"
)
# Install Programs using faltpak
flatpakId=(
    "com.visualstudio.code"
    "tv.plex.PlexDesktop"
    "com.brave.Browser"
)
# Install Programs using snap
snapId=(
    ""
)

# Set the region to English Denmark
export LC_ALL="en_DK.UTF-8"
sudo localectl set-locale LANG=en_DK.UTF-8

# Function to prompt choice
prompt_choice() {
    title="$1"
    prompt="$2"
    choices=("${!3}")
    default_choice=$4
    echo "$prompt"
    select choice in "${choices[@]}"; do
        REPLY="${REPLY:-$default_choice}"
        if [[ -n $choice ]]; then
            break
        else
            echo "Invalid choice."
        fi
    done
    echo "$REPLY"
}

# Prompt for choices
Backup=$(prompt_choice "Set up backup task schedule" "Do you want to activate backup?" "Yes No" 1)
Update=$(prompt_choice "Windows Update" "Do you want to install system updates?" "Yes No")

curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import

# Install packages from pacman
for PId in "${pacmanId[@]}"; do
    sudo pacman -S --noconfirm "$PId"
done

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd -
rm -rfd yay

# Install packages for yay
for YId in "${yayId[@]}"; do
    yay -Syu --noconfirm "$YId"
done

sudo ln -s /var/lib/snapd/snap /snap

# Install packages for flatpak
for FId in "${flatpakId[@]}"; do
    flatpak install flathub -y "$FId"
done

# Install packages from snap
for SId in "${snapId[@]}"; do
    sudo snap install --stable --classic  "$SID"
done

1password &
wait $!

killall 1password

# Customize KDE Plasma settings
kwriteconfig5 --file kdeglobals --group General --key ColorScheme "BreezeDark"
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Set power button behavior
kwriteconfig5 --file powerdevilrc --group "ButtonEventsHandling" --key "PowerButtonAction" "nothing"
kwriteconfig5 --file powerdevilrc --group "ButtonEventsHandling" --key "SleepButtonAction" "nothing"



sudo reboot
