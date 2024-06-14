#!/bin/bash

# Install Programs using pacman
pacmanId=(
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
    "com.brave.Browser"
)
# Install Programs using snap
snapId=(
    ""
)

# Set the region to English Denmark
export LC_ALL="en_DK.UTF-8"
sudo localectl set-locale LANG=en_DK.UTF-8

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

(1password &)
wait $!

killall 1password

# Customize KDE Plasma settings
lookandfeeltool --apply org.kde.breezedark.desktop

sudo reboot
