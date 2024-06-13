sudo pacman -S glib2-devel

mkdir -p ~/temp
cd ~/temp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd -
rm -rfd yay

yay -Syu pamac-all --noconfirm

sudo ln -s /var/lib/snapd/snap /snap