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

# Install language servers
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

# outro / todo
```
confirm XDG_RUNTIME_DIR is set

add LTS kernel

secure boot:
https://wiki.alpinelinux.org/wiki/UEFI_Secure_Boot

xdg-open configuration:
https://unix.stackexchange.com/questions/36380/how-to-properly-and-easily-configure-xdg-open-without-any-environment

qutebrowser flags:
qutebrowser --qt-flag ignore-gpu-blocklist --qt-flag enable-zero-copy --qt-flag enable-accelerated-video-decode --qt-flag enable-native-gpu-memory-buffers 
```

```
# Avoid overwriting resolv.conf by DHCP
mkdir -p /etc/udhcpc
tee /etc/udhcpc/udhcpc.conf << EOF
RESOLV_CONF="NO"
EOF

# Configure Cloudflare DNS servers
tee /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
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

# firmware
```
grubby --update-kernel=ALL --args='dyndbg="file drivers/base/firmware_loader/main.c +fmp"'

dmesg | grep firmware_class
dmesg | grep "Loading firmware from"

linux-firmware-intel
linux-firmware-i915 # intel graphics driver
linux-firmware-other # wifi - iwlwifi

linux-firmware-amd
linux-firmware-amd-ucode
linux-firmware-amdgpu
linux-firmware-other # wifi - iwlwifi
linux-firmware-intel # bluetooth - ibt
```