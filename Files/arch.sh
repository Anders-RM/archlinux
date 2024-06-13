#! /bin/bash
sudo pacman -S --noconfirm glib2-devel

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd -
rm -rfd yay

yay -Syu --noconfirm pamac-all 

sudo ln -s /var/lib/snapd/snap /snap

curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
yay -Syu --noconfirm 1password
yay -Syu --noconfirm 1password-cli

flatpak install flathub com.brave.Browser -y

sudo pacman -S --noconfirm code 
sudo pacman -S --noconfirm vlc
flatpak install flathub tv.plex.PlexDesktop -y

yay -Syu --noconfirm ttf-ms-win11-auto