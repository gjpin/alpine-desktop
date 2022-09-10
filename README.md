# Install
```
# Enable networking
setup-interfaces
rc-service networking start

# Download install script
wget https://raw.githubusercontent.com/gjpin/alpine-desktop/main/install.sh

# Run install script
chmod +x install.sh
./install.sh

# Reboot

# Login as root

# Download setup script
wget https://raw.githubusercontent.com/gjpin/alpine-desktop/main/setup.sh

# Run setup script
chmod +x setup.sh
./setup.sh

# Reboot

# Login as user

# Create all XDG directories
xdg-user-dirs-update

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Change npm default dir
npm config set prefix '~/.npm-global'

# Install language servers
go install golang.org/x/tools/gopls@latest
go install github.com/lighttiger2505/sqls@latest
go install github.com/hashicorp/terraform-ls@latest
npm install -g bash-language-server
npm install -g typescript-language-server typescript
npm install -g pyright

# Bootstrap neovim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
```

# Steam
```
apk add steam-devices
flatpak install -y com.valvesoftware.Steam
flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam
flatpak install -y com.valvesoftware.Steam.CompatibilityTool.Proton-GE
flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud
```

# KDE
```
# Setup system to use Xorg
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-xorg-base.in
apk add xorg-server xf86-input-libinput

# Install Plasma and enable services
# https://wiki.alpinelinux.org/wiki/KDE
# https://github.com/alpinelinux/alpine-conf/blob/master/setup-desktop.in
apk add plasma kde-applications-base elogind polkit-elogind

rc-update add elogind
rc-update add polkit
rc-update add udev
rc-update add sddm

# Use grub breeze theme (MISSING CORRECT THEME FILENAME)
tee -a /etc/default/grub << EOF
GRUB_THEME=/usr/share/grub/themes/breeze
GRUB_GFXMODE=1920x1080
EOF

grub-mkconfig -o /boot/grub/grub.cfg

# overview with meta key
kwriteconfig5 --file kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.kglobalaccel,/component/kwin,,invokeShortcut,Overview
```

# outro / todo
```
add LTS kernel

secure boot:
https://wiki.alpinelinux.org/wiki/UEFI_Secure_Boot

xdg-open configuration:
https://unix.stackexchange.com/questions/36380/how-to-properly-and-easily-configure-xdg-open-without-any-environment

qutebrowser flags:
qutebrowser --qt-flag ignore-gpu-blocklist --qt-flag enable-zero-copy --qt-flag enable-accelerated-video-decode --qt-flag enable-native-gpu-memory-buffers 
```


# To use swap file instead of lvm + swap partition
```
##### Swap
# Calculate swap size
# TOTAL_MEM_GB=$(free -g | grep Mem: | awk '{print $2}')
# SWAP_SIZE_MB=$((($TOTAL_MEM_GB + 1) * 1024))

# # Create swap file
# dd if=/dev/zero of=/swapfile bs=1M count=${SWAP_SIZE_MB} status=progress
# chmod 0600 /swapfile
# mkswap -U clear /swapfile
# swapon /swapfile
# echo '/swapfile none swap defaults 0 0' >>/etc/fstab

# # Start swap service
# rc-update add swap boot

https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
```