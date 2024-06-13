#! /bin/bash
sudo pacman -S --noconfirm glib2-devel

mkdir -p ~/temp
cd ~/temp
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